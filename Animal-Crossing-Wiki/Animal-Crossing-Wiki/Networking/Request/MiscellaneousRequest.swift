//
//  MiscellaneousRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import Foundation
import Alamofire

struct MiscellaneousRequest: APIRequest {
    typealias Response = MiscellaneousResponseDTO
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Miscellaneous.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
