//
//  FencingReqeust.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/23.
//

import Foundation
import Alamofire

struct FencingReqeust: APIRequest {
    typealias Response = [FencingResponseDTO]
    let method: HTTPMethod = .get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Fencing.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
