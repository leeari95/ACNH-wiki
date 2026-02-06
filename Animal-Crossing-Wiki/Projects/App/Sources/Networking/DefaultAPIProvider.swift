//
//  DefaultAPIProvider.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire
import OSLog
import RxSwift

struct DefaultAPIProvider: APIProvider {
    func request<T: APIRequest>(_ request: T, completion: @escaping (Result<T.Response, Error>) -> Void) {
        AF.request(request).responseDecodable(of: T.Response.self) { data in
            switch data.result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                debugPrint(error)
                completion(.failure(error))
            }
        }
    }

    func request<T: APIRequest>(_ request: T) -> Single<T.Response> {
        return Single.create { single in
            let dataRequest = AF.request(request)
                .responseDecodable(of: T.Response.self) { response in
                    switch response.result {
                    case .success(let value):
                        single(.success(value))
                    case .failure(let error):
                        single(.failure(error))
                    }
                }

            return Disposables.create {
                dataRequest.cancel()
            }
        }
    }
}
