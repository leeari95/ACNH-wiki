//
//  BottomsRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/18.
//

import Foundation
import Alamofire
import ACNHCore

struct BottomsRequest: APIRequest {
    typealias Response = [BottomsResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Bottoms.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
