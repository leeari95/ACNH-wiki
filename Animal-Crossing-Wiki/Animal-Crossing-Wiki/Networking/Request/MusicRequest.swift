//
//  MusicRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/20.
//

import Foundation
import Alamofire

struct MusicRequest: APIRequest {
    typealias Response = [String: MusicResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.acnhAPI)
    let path: String = "songs/"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
