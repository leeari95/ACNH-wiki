//
//  PhotosReqeust.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/17.
//

import Foundation
import Alamofire
import ACNHCore

struct PhotosReqeust: APIRequest {
    typealias Response = [PhotosResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Photos.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
