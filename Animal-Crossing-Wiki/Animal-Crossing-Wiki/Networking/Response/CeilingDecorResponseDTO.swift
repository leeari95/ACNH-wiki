//
//  CeilingDecorResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/16.
//

import Foundation

struct CeilingDecorResponseDTO: Codable, APIResponse {
    let name: String
    let diy: Bool
    let patternCustomize: Bool
    let kitCost: Int?
    let size: Size
    let sourceNotes: String?
    let versionAdded: String
    let interact: Bool
    let tag: String
    let outdoor: Bool
    let lightingType: String?
    let catalog: Catalog
    let bodyTitle: String?
    let bodyCustomize: Bool
    let buy, sell: Int
    let translations: Translations
    let source: [String]
    let seriesTranslations: Translations?
    let hhaBasePoints: Int
    let unlocked: Bool
    let variations: [Variant]
    let set: String?
    let series: String?
    let recipe: Recipe?
}

extension CeilingDecorResponseDTO {
    func toDomain() -> Item {
        let image = variations.first?.image
        return Item(
            name: name,
            category: .ceilingDecor,
            image: image,
            diy: diy,
            bodyCustomize: bodyCustomize,
            patternCustomize: patternCustomize,
            buy: buy,
            sell: sell,
            size: size,
            exchangePrice: variations.first?.exchangePrice,
            exchangeCurrency: variations.first?.exchangeCurrency,
            sources: source,
            hhaBasePoints: hhaBasePoints,
            hhaCategory: variations.first?.hhaCategory,
            tag: tag,
            catalog: catalog,
            internalId: variations.first?.internalId,
            translations: translations,
            colors: variations.first?.colors,
            concepts: variations.first?.concepts,
            set: set,
            series: series,
            recipe: recipe,
            seriesTranslations: seriesTranslations,
            variations: variations
        )
    }
}
