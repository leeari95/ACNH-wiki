//
//  OtherRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation
import Alamofire

struct OtherRequest: APIRequest {
    typealias Response = [OtherResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Other.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
