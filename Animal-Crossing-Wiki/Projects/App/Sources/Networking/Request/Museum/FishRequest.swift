//
//  FishRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire

struct FishRequest: APIRequest {
    typealias Response = [FishResponseDTO]
    let method: HTTPMethod = .get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Fish.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
