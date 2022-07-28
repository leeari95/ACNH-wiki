//
//  TurnipRequest.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import Alamofire

// MARK: - TurnipRequest
struct TurnipRequest: APIRequest {
    typealias Response = [TurnipResponseDTO]
    let method: HTTPMethod = .get
    let baseURL: URL? = URL(string: EnvironmentsVariable.turnupURL)
    let path: String = ""
    var headers: [String : String]?
    var parameters: [String : String] {
        return ["f": "\(buyPrice)-\(priceHistories.joined(separator: "-"))"]
    }
    
    let buyPrice: String
    let priceHistories: [String]
    
    init(buyPrice: String, priceHistories: [String]) {
        self.buyPrice = buyPrice
        self.priceHistories = priceHistories
    }
}
