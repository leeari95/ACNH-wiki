//
//  APIProvider.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

protocol APIProvider {
    func request<T: APIRequest>(
        _ request: T,
        completion: @escaping (Result<T.Response, Error>) -> Void
    )
}
