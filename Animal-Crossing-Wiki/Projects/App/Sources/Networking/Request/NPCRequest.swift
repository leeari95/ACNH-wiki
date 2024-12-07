//
//  NPCRequest.swift
//  ACNH-wiki
//
//  Created by Ari on 11/23/24.
//

import Foundation
import Alamofire

struct NPCRequest: APIRequest {
    typealias Response = [NPCResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Special NPCs.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
