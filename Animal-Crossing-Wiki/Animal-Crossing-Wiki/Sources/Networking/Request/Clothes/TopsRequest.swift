//
//  TopsRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/18.
//

import Foundation
import Alamofire

struct TopsRequest: APIRequest {
    typealias Response = [TopsResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Tops.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
