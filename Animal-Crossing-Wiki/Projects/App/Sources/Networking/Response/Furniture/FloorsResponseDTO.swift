//
//  FloorsResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation
import ACNHCore

struct FloorsResponseDTO: Decodable {

    let name: String
    let image: String
    let vfx: Bool
    let diy: Bool
    let buy, sell: Int
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
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

extension FloorsResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .floors,
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
