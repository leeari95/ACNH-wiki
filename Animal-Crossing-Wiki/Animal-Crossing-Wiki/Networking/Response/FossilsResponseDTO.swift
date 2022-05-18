//
//  FossilsResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - FossilsResponseDTO
struct FossilsResponseDTO: Codable, APIResponse {
    let name: String
    let image: String
    let buy: Int
    let sell: Int
    let fossilGroup: String
    let description: [String]
    let hhaBasePoints: Int
    let size: Size
    let museum: Museum
    let interact: Bool
    let filename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: [String: String]
    let colors: [Color]
}

enum Museum: String, Codable {
    case room1 = "Room 1"
    case room2 = "Room 2"
    case room3 = "Room 3"
}
