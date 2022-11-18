//
//  DressUpRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/18.
//

import Foundation
import Alamofire

struct DressUpRequest: APIRequest {
    typealias Response = [DressUpResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Dress-Up.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
