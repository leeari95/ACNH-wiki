//
//  GyroidsRequst.swift
//  ACNH-wiki
//
//  Created by Ari on 11/15/24.
//

import Foundation
import Alamofire
import ACNHCore

struct GyroidsRequst: APIRequest {
    typealias Response = [GyroidsResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Gyroids.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
