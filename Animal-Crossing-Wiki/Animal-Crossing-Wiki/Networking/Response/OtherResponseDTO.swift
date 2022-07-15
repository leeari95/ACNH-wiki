//
//  OtherResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation

struct OtherResponseDTO: Codable, APIResponse {
    
    let name: String
    let inventoryImage: String?
    let storageImage: String?
    let diy: Bool
    let stackSize: Int
    let buy: Int
    let sell: Int?
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let hhaBasePoints: Int
    let tag: String
    let foodPower: Int?
    let versionAdded: String
    let unlocked: Bool
    let inventoryFilename: String
    let storageFilename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let colors: [Color]
    let recipe: Recipe?
    
}
extension OtherResponseDTO {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .other,
            iconImage: inventoryImage,
            image: storageImage ?? inventoryImage,
            diy: diy,
            buy: buy,
            sell: sell,
            exchangePrice: exchangePrice,
            exchangeCurrency: exchangeCurrency,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            hhaBasePoints: hhaBasePoints,
            tag: tag,
            foodPower: foodPower,
            internalId: internalId,
            translations: translations,
            colors: colors,
            recipe: recipe
        )
    }
}
