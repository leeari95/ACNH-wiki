//
//  ToolsRequest.swift
//  ACNH-wiki
//
//  Created by Ari on 11/23/24.
//

import Foundation
import Alamofire

struct ToolsRequest: APIRequest {
    typealias Response = [ToolsResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Tools-Goods.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
