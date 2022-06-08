//
//  ArtRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire

struct ArtRequest: APIRequest {
    typealias Response = ArtResponseDTO
    let method: HTTPMethod = .get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Artwork.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
