//
//  UmbrellasResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation

struct UmbrellasResponseDTO: Codable {
    let name: String
    let storageImage: String
    let diy: Bool
    let buy, sell, hhaBasePoints: Int
    let size: Size
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let villagerEquippable: Bool
    let catalog: Catalog
    let versionAdded: String
    let unlocked: Bool
    let filename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let colors: [Color]
    let recipe: RecipeResponseDTO?
}

extension UmbrellasResponseDTO {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .umbrellas,
            image: storageImage,
            diy: diy,
            buy: buy,
            sell: sell,
            size: size,
            exchangePrice: exchangePrice,
            exchangeCurrency: exchangeCurrency,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            hhaBasePoints: hhaBasePoints,
            catalog: catalog,
            internalId: internalId,
            translations: translations,
            colors: colors,
            themes: nil,
            styles: [],
            recipe: recipe,
            variations: nil
        )
    }
}
