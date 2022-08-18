//
//  MusicRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/08/18.
//

import Foundation
import Alamofire

struct SongsRequest: APIRequest {
    typealias Response = [SongResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Music.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
