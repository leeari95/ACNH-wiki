//
//  WetSuitRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation
import Alamofire
import ACNHCore

struct WetSuitRequest: APIRequest {
    typealias Response = [WetSuitResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Clothing Other.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
