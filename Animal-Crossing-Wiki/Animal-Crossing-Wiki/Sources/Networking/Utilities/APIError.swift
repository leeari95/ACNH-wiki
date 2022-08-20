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
            return "캐스팅에 실패하였습니다."
        case .statusCode(let code, let message):
            return "상태 코드 에러 : \(code)\n 오류 메세지 : \(message)"
        case .notFoundURL:
            return "URL을 찾을 수 없습니다."
        case .invalidData:
            return "데이터가 유효하지 않습니다."
        case .invalidURL(let url):
            return "URL이 잘못되었습니다.\nURL: \(url)"
        case .parsingError:
            return "JSON으로 파싱하는 도중 알 수 없는 오류가 발생했습니다."
        }
    }
}
