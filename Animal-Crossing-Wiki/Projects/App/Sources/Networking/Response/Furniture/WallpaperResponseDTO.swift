//
//  WallpaperResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation

struct WallpaperResponseDTO: Decodable {
    let name: String //
    let image: String //
    let vfx: Bool
    let vfxType: String?
    let diy: Bool
    let buy: Int  //
    let sell: Int  //
    let exchangePrice: Int?  //
    let exchangeCurrency: ExchangeCurrency?  //
    let source: [String]  //
    let sourceNotes: [String]?  //
    let seasonEvent: String?  //
    let seasonEventExclusive: Bool?
    let windowType: String?  //
    let windowColor: String?  //
    let paneType: String?  //
    let curtainType: String?
    let curtainColor: String?  //
    let ceilingType: String
    let hhaBasePoints: Int
    let tag: String
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String
    let internalId: Int
    let uniqueEntryId: String
    let seriesTranslations: Translations?
    let translations: Translations
    let colors: [Color]
    let concepts: [String]
    let series: String?
    let recipe: RecipeResponseDTO?
}

extension WallpaperResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .wallpaper,
            image: image,
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
            catalog: catalog,
            internalId: internalId,
            translations: translations,
            colors: colors,
            series: series,
            recipe: recipe,
            seriesTranslations: seriesTranslations
        )
    }
}
