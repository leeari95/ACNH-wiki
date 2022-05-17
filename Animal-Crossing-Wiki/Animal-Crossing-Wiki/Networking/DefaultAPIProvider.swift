//
//  DefaultAPIProvider.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

struct DefaultAPIProvider: APIProvider {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func execute(request: URLRequest, completion: @escaping (Result<Data?, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(APIError.responseCasting))
                return
            }
            guard (200...299).contains(response.statusCode) else {
                completion(.failure(APIError.statusCode(
                    code: response.statusCode,
                    message: String(data: data ?? Data(), encoding: .utf8) ?? ""
                )))
                return
            }
            completion(.success(data))
        }.resume()
    }

    func request<T: APIRequest>(_ request: T, completion: @escaping (Result<T.Response, Error>) -> Void) {
        guard let urlRequest = request.urlReqeust else {
            return
        }

        execute(request: urlRequest) { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    return completion(.failure(APIError.invalidData))
                }
                let decoder = JSONDecoder()
                guard let decoded = try? decoder.decode(T.Response.self, from: data) else {
                    return completion(.failure(APIError.parsingError))
                }
                return completion(.success(decoded))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func requestList<T: APIRequest>(_ request: T, completion: @escaping (Result<[T.Response], Error>) -> Void) {
        guard let urlRequest = request.urlReqeust else {
            return
        }

        execute(request: urlRequest) { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    return completion(.failure(APIError.invalidData))
                }
                let decoder = JSONDecoder()
                guard let decoded = try? decoder.decode([T.Response].self, from: data) else {
                    return completion(.failure(APIError.parsingError))
                }
                return completion(.success(decoded))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

enum APIError: LocalizedError {
    case responseCasting
    case statusCode(code: Int, message: String)
    case notFoundURL
    case invalidData
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
        case .parsingError:
            return "JSON으로 파싱하는 도중 알 수 없는 오류가 발생했습니다."
        }
    }
}
