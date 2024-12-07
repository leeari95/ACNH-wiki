//
//  WallpaperRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation
import Alamofire

struct WallpaperRequest: APIRequest {
    typealias Response = [WallpaperResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Wallpaper.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
