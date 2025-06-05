//
//  ReactionsRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/23.
//

import Foundation
import Alamofire
import ACNHCore

struct ReactionsRequest: APIRequest {
    typealias Response = [ReactionsResponseDTO]
    let method: HTTPMethod = .get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Reactions.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
