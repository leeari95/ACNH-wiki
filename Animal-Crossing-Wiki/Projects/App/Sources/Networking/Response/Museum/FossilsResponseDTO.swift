//
//  FossilsResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - FossilsResponseDTO
struct FossilsResponseDTO: Decodable {
    let name: String
    let image: String
    let buy: Int
    let sell: Int
    let fossilGroup: String
    let description: [String]
    let hhaBasePoints: Int
    let size: Size
    let source: [String]
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

extension FossilsResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: self.name,
            category: .fossils,
            image: self.image,
            buy: self.buy,
            sell: self.sell,
            size: self.size,
            source: self.source.first ?? "",
            museum: self.museum,
            translations: self.translations,
            colors: self.colors
        )
    }
}
extension Item {

    init(
        name: String,
        category: Category,
        image: String,
        buy: Int,
        sell: Int,
        size: Size,
        source: String,
        museum: Museum,
        translations: Translations,
        colors: [Color]
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.buy = buy
        self.sell = sell
        self.size = size
        self.source = source
        self.museum = museum
        self.translations = translations
        self.colors = colors
        self.genuine = true
    }

}
