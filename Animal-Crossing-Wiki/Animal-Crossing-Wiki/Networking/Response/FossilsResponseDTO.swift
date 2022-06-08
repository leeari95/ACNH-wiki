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
    let translations: Translations
    let colors: [Color]
}

enum Museum: String, Codable {
    case room1 = "Room 1"
    case room2 = "Room 2"
    case room3 = "Room 3"
}

extension FossilsResponseDTO {
    func toDomain() -> Fossils {
        return Fossils(
            name: self.name,
            image: self.image,
            buy: self.buy,
            sell: self.sell,
            size: self.size,
            museum: self.museum,
            translations: self.translations,
            colors: self.colors
        )
    }
}
