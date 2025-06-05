//
//  VillagersRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire
import ACNHCore

struct VillagersRequest: APIRequest {
    typealias Response = [VillagersResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Villagers.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
