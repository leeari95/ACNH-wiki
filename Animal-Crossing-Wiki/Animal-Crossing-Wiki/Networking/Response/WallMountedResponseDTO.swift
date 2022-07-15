//
//  WallMountedResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import Foundation

struct WallMountedResponseDTO: Codable, APIResponse {
    
    let name: String
    let image: String?
    let variation: String?
    let bodyTitle: String?
    let pattern: String?
    let patternTitle: String?
    let diy: Bool
    let bodyCustomize: Bool
    let patternCustomize: Bool
    let kitCost: Int?
    let kitType: String?
    let cyrusCustomizePrice: String?
    let buy: Int
    let sell: Int
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let size: Size
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let hhaBasePoints: Int
    let hhaCategory: HhaCategory?
    let interact: InteractUnion
    let tag: String
    let outdoor: Bool
    let lightingType: LightingType?
    let doorDeco: Bool?
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String?
    let variantId: String?
    let internalId: Int?
    let uniqueEntryId: String?
    let seriesTranslations: Translations?
    let translations: Translations
    let colors: [Color]?
    let concepts: [Concept]?
    let set: String?
    let series: String?
    let recipe: Recipe?
    let variations: [Variant]?

}

extension WallMountedResponseDTO {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .housewares,
            image: image,
            variation: variation,
            bodyTitle: bodyTitle,
            pattern: pattern,
            patternTitle: patternTitle,
            diy: diy,
            bodyCustomize: bodyCustomize,
            patternCustomize: patternCustomize,
            buy: buy,
            sell: sell,
            size: size,
            exchangePrice: exchangePrice,
            exchangeCurrency: exchangeCurrency,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            hhaCategory: hhaCategory,
            tag: tag,
            outdoor: outdoor,
            lightingType: lightingType,
            catalog: catalog,
            internalId: internalId,
            translations: translations,
            colors: colors,
            concepts: concepts,
            set: set,
            series: series,
            recipe: recipe,
            seriesTranslations: seriesTranslations,
            variations: variations,
            doorDeco: doorDeco
        )
    }
}
