//
//  AccessoriesRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation
import Alamofire
import ACNHCore

struct AccessoriesRequest: APIRequest {
    typealias Response = [AccessoriesResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Accessories.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
