//
//  HeadwearRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/18.
//

import Foundation
import Alamofire

struct HeadwearRequest: APIRequest {
    typealias Response = [HeadwearResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Headwear.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
