//
//  SocksResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/21.
//

import Foundation

struct SocksResponseDTO: Decodable {
    let name: String
    let diy: Bool
    let size: Size
    let sourceNotes: [String]?
    let versionAdded: String
    let catalog: Catalog?
    let buy, sell: Int
    let translations: Translations
    let source: [String]
    let themesTranslations: [String: Translations]?
    let hhaBasePoints: Int
    let villagerEquippable: Bool
    let seasonalAvailability: String
    let unlocked: Bool
    let variations: [WardrobeVariat]?
    let styles: [Style]
    let themes: [Theme]
    let closetImage, storageImage: String?
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let seasonEvent, seasonEventExclusive: String?
    let seasonality: String?
    let mannequinSeason: String?
    let sortOrder: Int?
    let filename: String?
    let clothGroupId, internalId: Int?
    let uniqueEntryId: String?
    let colors: [Color]?
}

extension SocksResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .socks,
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
            recipe: nil,
            variations: variations?.map { $0.toVariat() }
        )
    }
}
