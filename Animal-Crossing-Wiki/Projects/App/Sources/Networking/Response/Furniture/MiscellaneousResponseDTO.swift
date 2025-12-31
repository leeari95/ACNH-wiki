//
//  MiscellaneousResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import Foundation

struct MiscellaneousResponseDTO: Decodable {

    let name: String
    let image: String?
    let variation: String?
    let bodyTitle: String?
    let pattern: String?
    let patternTitle: String?
    let diy: Bool
    let bodyCustomize: Bool
    let patternCustomize: Bool
    let stackSize: Int?
    let kitCost: Int?
    let kitType: String?
    let cyrusCustomizePrice: String?
    let buy: Int
    let sell: Int
    let size: Size
    let surface: Bool?
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let hhaBasePoints: Int
    let hhaCategory: HhaCategory?
    let interact: InteractUnion
    let tag: String
    let outdoor: Bool
    let speakerType: String?
    let lightingType: LightingType?
    let foodPower: Int?
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
    let recipe: RecipeResponseDTO?
    let variations: [Variant]?

}

extension MiscellaneousResponseDTO: DomainConvertible {

    private static let flowerPatterns: [String] = [
        "cosmos", "rose", "tulip", "lily", "lilies", "pansy", "pansies",
        "hyacinth", "windflower", "mum", "lily-of-the-valley"
    ]

    private var isFlower: Bool {
        guard tag.lowercased() == "plants" else { return false }
        let lowercasedName = name.lowercased()
        return Self.flowerPatterns.contains { lowercasedName.contains($0) }
    }

    func toDomain() -> Item {
        let image = image ?? variations?.first?.image

        let category: Category
        if foodPower != nil {
            category = .cooking
        } else if isFlower {
            category = .flowers
        } else {
            category = .miscellaneous
        }

        return Item(
            name: name,
            category: category,
            image: image,
            diy: diy,
            bodyCustomize: bodyCustomize,
            patternCustomize: patternCustomize,
            buy: buy,
            sell: sell,
            size: size,
            exchangePrice: exchangePrice ?? variations?.first?.exchangePrice,
            exchangeCurrency: exchangeCurrency,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            hhaBasePoints: hhaBasePoints,
            hhaCategory: hhaCategory,
            tag: tag,
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
            foodPower: foodPower
        )
    }
}
