//
//  RecipesRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/20.
//

import Foundation
import Alamofire
import ACNHCore

struct RecipesRequest: APIRequest {
    typealias Response = [RecipeResponseDTO]
    let method: HTTPMethod = HTTPMethod.get
    let baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    let path: String = "Recipes.json"
    var headers: [String: String]? = [:]
    var parameters: [String: String] {
        return [:]
    }
}
