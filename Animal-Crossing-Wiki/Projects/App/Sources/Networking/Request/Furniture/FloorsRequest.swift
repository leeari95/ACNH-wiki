//
//  FloorsRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation
import Alamofire
import ACNHCore

struct FloorsRequest: APIRequest {
    typealias Response = [FloorsResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Floors.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
