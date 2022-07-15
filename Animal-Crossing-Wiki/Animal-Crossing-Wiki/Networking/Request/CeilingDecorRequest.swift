//
//  CeilingDecorRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/16.
//

import Foundation
import Alamofire

struct CeilingDecorRequest: APIRequest {
    typealias Response = CeilingDecorResponseDTO
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Ceiling Decor.json"
    var headers: [String : String]? = [:]
    var parameters: [String : String] {
        return [:]
    }
}
