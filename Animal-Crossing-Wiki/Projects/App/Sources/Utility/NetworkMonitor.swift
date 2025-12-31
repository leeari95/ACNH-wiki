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

/// 네트워크 연결 상태를 모니터링하고, 실패한 요청을 자동 재시도하는 기능을 제공합니다.
final class NetworkMonitor {

    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Types
    enum ConnectionStatus {
        case connected
        case disconnected

        var isConnected: Bool {
            self == .connected
        }
    }

    struct PendingRequest {
        let id: UUID
        let execute: () -> Void
        let createdAt: Date
        let retryCount: Int
        let maxRetries: Int

        func incrementRetry() -> PendingRequest {
            PendingRequest(
                id: id,
                execute: execute,
                createdAt: createdAt,
                retryCount: retryCount + 1,
                maxRetries: maxRetries
            )
        }
    }

    // MARK: - Properties
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.animal-crossing-wiki.network-monitor", qos: .utility)
    private let disposeBag = DisposeBag()

    private let connectionStatusRelay = BehaviorRelay<ConnectionStatus>(value: .connected)
    private let pendingRequestsRelay = BehaviorRelay<[PendingRequest]>(value: [])

    /// 현재 네트워크 연결 상태
    var connectionStatus: Observable<ConnectionStatus> {
        connectionStatusRelay.asObservable().distinctUntilChanged()
    }

    /// 현재 연결 상태 (동기)
    var isConnected: Bool {
        connectionStatusRelay.value.isConnected
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
    private init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.monitor = NWPathMonitor()

        setupMonitoring()
        setupConnectionRecoveryHandler()
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

    /// 실패한 요청을 대기 큐에 추가합니다.
    /// - Parameters:
    ///   - execute: 재시도할 요청 클로저
    ///   - maxRetries: 최대 재시도 횟수 (기본값: Configuration의 maxRetries)
    /// - Returns: 요청 ID
    @discardableResult
    func enqueuePendingRequest(
        maxRetries: Int? = nil,
        execute: @escaping () -> Void
    ) -> UUID {
        let request = PendingRequest(
            id: UUID(),
            execute: execute,
            createdAt: Date(),
            retryCount: 0,
            maxRetries: maxRetries ?? configuration.maxRetries
        )

        var requests = pendingRequestsRelay.value
        requests.append(request)
        pendingRequestsRelay.accept(requests)

        return request.id
    }

    /// 특정 요청을 대기 큐에서 제거합니다.
    /// - Parameter id: 제거할 요청의 ID
    func removePendingRequest(id: UUID) {
        var requests = pendingRequestsRelay.value
        requests.removeAll { $0.id == id }
        pendingRequestsRelay.accept(requests)
    }

    /// 모든 대기 요청을 제거합니다.
    func clearPendingRequests() {
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
        let requests = pendingRequestsRelay.value
        let validRequests = filterExpiredRequests(requests)

        guard !validRequests.isEmpty else {
            pendingRequestsRelay.accept([])
            return
        }

        // 대기 큐 초기화
        pendingRequestsRelay.accept([])

        // 각 요청을 지수 백오프로 재시도
        for (index, request) in validRequests.enumerated() {
            let delay = calculateBackoffDelay(retryCount: request.retryCount)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(index) * 0.1) {
                request.execute()
            }
        }
    }

    private func filterExpiredRequests(_ requests: [PendingRequest]) -> [PendingRequest] {
        let now = Date()
        return requests.filter { request in
            let isNotExpired = now.timeIntervalSince(request.createdAt) < configuration.requestTimeout
            let hasRetriesLeft = request.retryCount < request.maxRetries
            return isNotExpired && hasRetriesLeft
        }.map { $0.incrementRetry() }
    }
}
