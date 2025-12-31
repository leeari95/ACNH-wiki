//
//  NetworkMonitor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import Foundation
import Network
import RxSwift
import RxRelay

// MARK: - Protocol

/// 네트워크 모니터링 인터페이스 (테스트 용이성을 위한 프로토콜)
protocol NetworkMonitoring {
    var connectionStatus: Observable<NetworkMonitor.ConnectionStatus> { get }
    var isConnected: Bool { get }
    var isConnectionStatusKnown: Bool { get }
    var pendingRequestCount: Observable<Int> { get }

    func startMonitoring()
    func stopMonitoring()
    func restartMonitoring()

    @discardableResult
    func enqueuePendingRequest(
        maxRetries: Int?,
        onExecute: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) -> UUID

    func removePendingRequest(id: UUID)
    func clearPendingRequests()
    func calculateBackoffDelay(retryCount: Int) -> TimeInterval
}

// MARK: - NetworkMonitor

/// 네트워크 연결 상태를 모니터링하고, 실패한 요청을 자동 재시도하는 기능을 제공합니다.
final class NetworkMonitor: NetworkMonitoring {

    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Types
    enum ConnectionStatus: Equatable {
        case connected
        case disconnected
        case unknown

        var isConnected: Bool {
            self == .connected
        }
    }

    struct PendingRequest {
        let id: UUID
        let onExecute: () -> Void
        let onFailure: (Error) -> Void
        let createdAt: Date
        let retryCount: Int
        let maxRetries: Int

        func incrementRetry() -> PendingRequest {
            PendingRequest(
                id: id,
                onExecute: onExecute,
                onFailure: onFailure,
                createdAt: createdAt,
                retryCount: retryCount + 1,
                maxRetries: maxRetries
            )
        }
    }

    /// 대기 요청 만료 에러
    enum PendingRequestError: LocalizedError {
        case expired
        case maxRetriesExceeded

        var errorDescription: String? {
            switch self {
            case .expired:
                return NSLocalizedString("network_monitor_request_expired", comment: "Request expired while waiting for network")
            case .maxRetriesExceeded:
                return NSLocalizedString("network_monitor_max_retries", comment: "Maximum retry count exceeded")
            }
        }
    }

    // MARK: - Properties
    private var monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.animal-crossing-wiki.network-monitor", qos: .utility)
    private let pendingRequestsLock = NSLock()
    private let disposeBag = DisposeBag()

    /// 초기값을 unknown으로 설정하여 실제 상태가 확인되기 전까지 연결 상태를 알 수 없음을 표시
    private let connectionStatusRelay = BehaviorRelay<ConnectionStatus>(value: .unknown)
    private let pendingRequestsRelay = BehaviorRelay<[PendingRequest]>(value: [])

    /// 현재 네트워크 연결 상태
    var connectionStatus: Observable<ConnectionStatus> {
        connectionStatusRelay.asObservable().distinctUntilChanged()
    }

    /// 현재 연결 상태 (동기)
    /// - Note: 상태가 unknown인 경우 true를 반환하여 낙관적으로 요청을 시도합니다.
    ///         실제 네트워크가 없으면 요청 실패 시 재시도 로직이 처리합니다.
    var isConnected: Bool {
        let status = connectionStatusRelay.value
        // unknown 상태에서는 낙관적으로 연결됨으로 간주
        return status == .connected || status == .unknown
    }

    /// 연결 상태가 확인되었는지 여부
    var isConnectionStatusKnown: Bool {
        connectionStatusRelay.value != .unknown
    }

    /// 대기 중인 요청 수
    var pendingRequestCount: Observable<Int> {
        pendingRequestsRelay.asObservable().map { $0.count }
    }

    // MARK: - Configuration
    struct Configuration {
        /// 기본 최대 재시도 횟수
        let maxRetries: Int
        /// 기본 재시도 지연 시간 (초)
        let baseDelay: TimeInterval
        /// 최대 재시도 지연 시간 (초)
        let maxDelay: TimeInterval
        /// 대기 요청 만료 시간 (초)
        let requestTimeout: TimeInterval

        static let `default` = Configuration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            requestTimeout: 300.0 // 5분
        )
    }

    private let configuration: Configuration

    // MARK: - Initialization

    /// 싱글톤용 private 초기화 (자동으로 모니터링 시작)
    private init() {
        self.configuration = .default
        self.monitor = NWPathMonitor()

        setupMonitoring()
        setupConnectionRecoveryHandler()

        // 싱글톤 초기화 시 자동으로 모니터링 시작
        startMonitoring()
    }

    /// 테스트용 초기화 메서드
    /// - Note: 테스트 환경에서만 사용하세요. 프로덕션에서는 NetworkMonitor.shared를 사용하세요.
    /// - Parameters:
    ///   - configuration: 네트워크 모니터 설정
    ///   - autoStart: 자동으로 모니터링을 시작할지 여부 (기본값: true)
    internal init(configuration: Configuration, autoStart: Bool = true) {
        self.configuration = configuration
        self.monitor = NWPathMonitor()

        setupMonitoring()
        setupConnectionRecoveryHandler()

        if autoStart {
            startMonitoring()
        }
    }

    // MARK: - Public Methods

    /// 네트워크 모니터링을 시작합니다.
    func startMonitoring() {
        monitor.start(queue: monitorQueue)
    }

    /// 네트워크 모니터링을 중지합니다.
    func stopMonitoring() {
        monitor.cancel()
    }

    /// 네트워크 모니터링을 재시작합니다.
    /// NWPathMonitor는 cancel() 후 재사용이 불가능하므로 새 인스턴스를 생성합니다.
    func restartMonitoring() {
        monitor.cancel()
        monitor = NWPathMonitor()
        setupMonitoring()
        startMonitoring()
    }

    /// 실패한 요청을 대기 큐에 추가합니다.
    /// - Parameters:
    ///   - maxRetries: 최대 재시도 횟수 (기본값: Configuration의 maxRetries)
    ///   - onExecute: 재시도할 요청 클로저
    ///   - onFailure: 요청이 만료되거나 재시도 횟수를 초과했을 때 호출되는 실패 콜백
    /// - Returns: 요청 ID
    @discardableResult
    func enqueuePendingRequest(
        maxRetries: Int? = nil,
        onExecute: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) -> UUID {
        let request = PendingRequest(
            id: UUID(),
            onExecute: onExecute,
            onFailure: onFailure,
            createdAt: Date(),
            retryCount: 0,
            maxRetries: maxRetries ?? configuration.maxRetries
        )

        pendingRequestsLock.lock()
        defer { pendingRequestsLock.unlock() }

        var requests = pendingRequestsRelay.value
        requests.append(request)
        pendingRequestsRelay.accept(requests)

        return request.id
    }

    /// 특정 요청을 대기 큐에서 제거합니다.
    /// - Parameter id: 제거할 요청의 ID
    func removePendingRequest(id: UUID) {
        pendingRequestsLock.lock()
        defer { pendingRequestsLock.unlock() }

        var requests = pendingRequestsRelay.value
        requests.removeAll { $0.id == id }
        pendingRequestsRelay.accept(requests)
    }

    /// 모든 대기 요청을 제거합니다.
    func clearPendingRequests() {
        pendingRequestsLock.lock()
        defer { pendingRequestsLock.unlock() }

        pendingRequestsRelay.accept([])
    }

    /// 지수 백오프 지연 시간을 계산합니다.
    /// - Parameter retryCount: 현재 재시도 횟수
    /// - Returns: 지연 시간 (초)
    func calculateBackoffDelay(retryCount: Int) -> TimeInterval {
        let exponentialDelay = configuration.baseDelay * pow(2.0, Double(retryCount))
        let jitter = Double.random(in: 0...0.5) * exponentialDelay
        return min(exponentialDelay + jitter, configuration.maxDelay)
    }

    // MARK: - Private Methods

    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let status: ConnectionStatus = path.status == .satisfied ? .connected : .disconnected

            DispatchQueue.main.async {
                self.connectionStatusRelay.accept(status)
            }
        }
    }

    private func setupConnectionRecoveryHandler() {
        connectionStatus
            .skip(1) // 초기 값 무시
            .filter { $0.isConnected }
            .subscribe(onNext: { [weak self] _ in
                self?.processPendingRequests()
            })
            .disposed(by: disposeBag)
    }

    private func processPendingRequests() {
        pendingRequestsLock.lock()
        let requests = pendingRequestsRelay.value
        let (validRequests, expiredRequests) = partitionRequests(requests)
        // 대기 큐 초기화
        pendingRequestsRelay.accept([])
        pendingRequestsLock.unlock()

        // 만료된 요청들에 대해 onFailure 콜백 호출
        for request in expiredRequests {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let error = self.determineFailureReason(for: request)
                request.onFailure(error)
            }
        }

        guard !validRequests.isEmpty else { return }

        // 각 요청을 지수 백오프로 재시도
        for (index, request) in validRequests.enumerated() {
            let delay = calculateBackoffDelay(retryCount: request.retryCount)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(index) * 0.1) {
                request.onExecute()
            }
        }
    }

    /// 요청을 유효한 것과 만료된 것으로 분류합니다.
    private func partitionRequests(_ requests: [PendingRequest]) -> (valid: [PendingRequest], expired: [PendingRequest]) {
        let now = Date()
        var valid: [PendingRequest] = []
        var expired: [PendingRequest] = []

        for request in requests {
            let isNotExpired = now.timeIntervalSince(request.createdAt) < configuration.requestTimeout
            let hasRetriesLeft = request.retryCount < request.maxRetries

            if isNotExpired && hasRetriesLeft {
                valid.append(request.incrementRetry())
            } else {
                expired.append(request)
            }
        }

        return (valid, expired)
    }

    /// 요청 실패 이유를 결정합니다.
    private func determineFailureReason(for request: PendingRequest) -> PendingRequestError {
        let now = Date()
        let isExpired = now.timeIntervalSince(request.createdAt) >= configuration.requestTimeout

        if isExpired {
            return .expired
        } else {
            return .maxRetriesExceeded
        }
    }
}
