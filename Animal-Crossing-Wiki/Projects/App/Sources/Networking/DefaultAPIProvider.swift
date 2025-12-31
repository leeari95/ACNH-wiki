//
//  DefaultAPIProvider.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire
import OSLog

struct DefaultAPIProvider: APIProvider {

    // MARK: - Configuration
    struct RetryConfiguration {
        /// 최대 재시도 횟수
        let maxRetries: Int
        /// 기본 지연 시간 (초)
        let baseDelay: TimeInterval
        /// 최대 지연 시간 (초)
        let maxDelay: TimeInterval
        /// 네트워크 복구 시 자동 재시도 활성화
        let enableAutoRetryOnReconnect: Bool

        static let `default` = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            enableAutoRetryOnReconnect: true
        )
    }

    private let networkMonitor: NetworkMonitor
    private let configuration: RetryConfiguration

    // MARK: - Initialization
    init(
        networkMonitor: NetworkMonitor = .shared,
        configuration: RetryConfiguration = .default
    ) {
        self.networkMonitor = networkMonitor
        self.configuration = configuration
    }

    // MARK: - APIProvider
    func request<T: APIRequest>(
        _ request: T,
        completion: @escaping (Result<T.Response, Error>) -> Void
    ) {
        requestWithRetry(request, retryCount: 0, completion: completion)
    }

    // MARK: - Private Methods

    /// 재시도 로직이 포함된 요청 메서드
    private func requestWithRetry<T: APIRequest>(
        _ request: T,
        retryCount: Int,
        completion: @escaping (Result<T.Response, Error>) -> Void
    ) {
        // 네트워크 연결 확인
        guard networkMonitor.isConnected else {
            handleNetworkUnavailable(request, completion: completion)
            return
        }

        AF.request(request).responseDecodable(of: T.Response.self) { response in
            switch response.result {
            case .success(let data):
                completion(.success(data))

            case .failure(let error):
                self.handleRequestFailure(
                    request: request,
                    error: error,
                    retryCount: retryCount,
                    completion: completion
                )
            }
        }
    }

    /// 네트워크 연결이 없을 때 처리
    private func handleNetworkUnavailable<T: APIRequest>(
        _ request: T,
        completion: @escaping (Result<T.Response, Error>) -> Void
    ) {
        os_log(
            .info,
            log: .default,
            "Network unavailable - enqueueing request for retry: %@",
            String(describing: T.self)
        )

        if configuration.enableAutoRetryOnReconnect {
            // 네트워크 복구 시 자동 재시도를 위해 대기 큐에 추가
            networkMonitor.enqueuePendingRequest(maxRetries: configuration.maxRetries) { [self] in
                self.request(request, completion: completion)
            }
        }

        completion(.failure(APIError.networkUnavailable))
    }

    /// 요청 실패 처리
    private func handleRequestFailure<T: APIRequest>(
        request: T,
        error: AFError,
        retryCount: Int,
        completion: @escaping (Result<T.Response, Error>) -> Void
    ) {
        let apiError = mapToAPIError(error)

        // 재시도 가능한 에러인지 확인
        guard shouldRetry(error: apiError, retryCount: retryCount) else {
            logFailure(request: request, error: error, retryCount: retryCount, willRetry: false)

            if retryCount > 0 {
                completion(.failure(APIError.retryExhausted(originalError: error)))
            } else {
                completion(.failure(error))
            }
            return
        }

        logFailure(request: request, error: error, retryCount: retryCount, willRetry: true)

        // 지수 백오프 적용
        let delay = calculateBackoffDelay(retryCount: retryCount)

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.requestWithRetry(request, retryCount: retryCount + 1, completion: completion)
        }
    }

    /// 재시도 여부 결정
    private func shouldRetry(error: APIError?, retryCount: Int) -> Bool {
        guard retryCount < configuration.maxRetries else { return false }
        guard let error = error else { return false }
        return error.isRetryable
    }

    /// AFError를 APIError로 변환
    private func mapToAPIError(_ error: AFError) -> APIError? {
        switch error {
        case .sessionTaskFailed(let urlError as URLError):
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
                return .networkUnavailable
            case .timedOut:
                return .statusCode(code: 408, message: "Request Timeout")
            default:
                return nil
            }

        case .responseValidationFailed(let reason):
            if case .unacceptableStatusCode(let code) = reason {
                return .statusCode(code: code, message: "HTTP \(code)")
            }
            return nil

        default:
            return nil
        }
    }

    /// 지수 백오프 지연 시간 계산
    private func calculateBackoffDelay(retryCount: Int) -> TimeInterval {
        let exponentialDelay = configuration.baseDelay * pow(2.0, Double(retryCount))
        // 무작위 지터(jitter) 추가로 thundering herd 문제 방지
        let jitter = Double.random(in: 0...0.5) * exponentialDelay
        return min(exponentialDelay + jitter, configuration.maxDelay)
    }

    /// 실패 로그 기록
    private func logFailure<T: APIRequest>(
        request: T,
        error: Error,
        retryCount: Int,
        willRetry: Bool
    ) {
        let retryInfo = willRetry
            ? "Retrying (\(retryCount + 1)/\(configuration.maxRetries))..."
            : "No more retries."

        os_log(
            .error,
            log: .default,
            "Request failed: %@ - Error: %@ - %@",
            String(describing: T.self),
            error.localizedDescription,
            retryInfo
        )
    }
}
