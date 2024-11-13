//
//  ShoesRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation
import Alamofire

struct ShoesRequest: APIRequest {
    typealias Response = [ShoesResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Shoes.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
