//
//  ShoesResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation

struct ShoesResponseDTO: Codable {
    let name: String
    let closetImage, storageImage: String?
    let diy: Bool
    let buy, sell, hhaBasePoints: Int
    let size: Size
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let seasonalAvailability: String
    let seasonality: String?
    let mannequinSeason: String?
    let sortOrder: Int?
    let villagerEquippable: Bool
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String?
    let clothGroupId, internalId: Int?
    let uniqueEntryId: String?
    let themesTranslations: [String: Translations]?
    let translations: Translations
    let colors: [Color]?
    let styles: [Style]
    let themes: [Theme]
    let recipe: RecipeResponseDTO?
    let variations: [WardrobeVariat]?
}

extension ShoesResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .shoes,
            image: closetImage ?? variations?.first?.closetImage,
            diy: diy,
            buy: buy,
            sell: sell,
            size: size,
            exchangePrice: exchangePrice ?? variations?.first?.exchangePrice,
            exchangeCurrency: exchangeCurrency,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            hhaBasePoints: hhaBasePoints,
            catalog: catalog,
            internalId: internalId,
            translations: translations,
            colors: colors,
            themes: themesTranslations?.values.map { $0.localizedName() },
            styles: styles,
            recipe: recipe,
            variations: variations?.map { $0.toVariat() }
        )
    }
}
