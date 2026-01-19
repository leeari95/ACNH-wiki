//
//  APIError.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/27.
//

import Foundation

enum APIError: LocalizedError {
    case responseCasting
    case statusCode(code: Int, message: String)
    case notFoundURL
    case invalidData
    case invalidURL(_ url: String)
    case parsingError
    case networkUnavailable
    case retryExhausted(originalError: Error)

    var errorDescription: String? {
        switch self {
        case .responseCasting:
            return NSLocalizedString("api_error_response_casting", comment: "Response casting failed")
        case .statusCode(let code, let message):
            return String(format: NSLocalizedString("api_error_status_code", comment: "Status code error"), code, message)
        case .notFoundURL:
            return NSLocalizedString("api_error_not_found_url", comment: "URL not found")
        case .invalidData:
            return NSLocalizedString("api_error_invalid_data", comment: "Invalid data")
        case .invalidURL(let url):
            return String(format: NSLocalizedString("api_error_invalid_url", comment: "Invalid URL"), url)
        case .parsingError:
            return NSLocalizedString("api_error_parsing", comment: "JSON parsing error")
        case .networkUnavailable:
            return NSLocalizedString("api_error_network_unavailable", comment: "Network unavailable")
        case .retryExhausted(let originalError):
            return String(
                format: NSLocalizedString("api_error_retry_exhausted", comment: "Retry exhausted"),
                originalError.localizedDescription
            )
        }
    }
}

// MARK: - Retry Helper
extension APIError {
    /// 재시도 가능한 에러인지 확인합니다.
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable:
            return true
        case .statusCode(let code, _):
            // 5xx 서버 에러, 408 Request Timeout, 429 Too Many Requests는 재시도 가능
            return (500...599).contains(code) || code == 408 || code == 429
        default:
            return false
        }
    }
}
