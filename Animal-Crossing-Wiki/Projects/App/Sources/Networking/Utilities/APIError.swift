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
        }
    }
}
