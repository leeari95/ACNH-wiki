//
//  UmbrellasRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation
import Alamofire

struct UmbrellasRequest: APIRequest {
    typealias Response = [UmbrellasResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Umbrellas.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
