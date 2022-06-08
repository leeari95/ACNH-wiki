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
    func request<T: APIRequest>(_ request: T, completion: @escaping (Result<T.Response, Error>) -> Void) {
        AF.request(request).responseDecodable(of: T.Response.self) { data in
            switch data.result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 네트워크 요청에 실패하였습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
        }
    }
    
    func requestList<T: APIRequest>(_ request: T, completion: @escaping (Result<[T.Response], Error>) -> Void) {
        AF.request(request).responseDecodable(of: [T.Response].self) { data in
            switch data.result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 네트워크 요청에 실패하였습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
        }
    }
}
