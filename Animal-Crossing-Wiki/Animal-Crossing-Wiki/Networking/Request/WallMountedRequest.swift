//
//  WallMountedRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import Foundation
import Alamofire

struct WallMountedRequest: APIRequest {
    typealias Response = [WallMountedResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Wall-mounted.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
