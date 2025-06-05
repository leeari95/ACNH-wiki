//
//  SeaCreaturesRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire
import ACNHCore

struct SeaCreaturesRequest: APIRequest {
    typealias Response = [SeaCreaturesResponseDTO]
    let method: HTTPMethod = .get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Sea Creatures.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
