//
//  ToolsResponseDTO.swift
//  ACNH-wiki
//
//  Created by Ari on 11/23/24.
//

import Foundation
import ACNHCore

struct ToolsResponseDTO: Decodable {
    let name: String
    let image: String?
    let bodyTitle: String?
    let diy, customize: Bool
    let kitCost: Int?
    let stackSize: Int?
    let buy: Int
    let sell: Int?
    let hhaBasePoints: Int
    let size: Size
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let villagerEquippable: Bool
    let foodPower: Int?
    let lightingType: String?
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String?
    let internalID: Int?
    let uniqueEntryID: String?
    let translations: Translations
    let colors: [Color]?
    let concepts: [Concept]?
    let recipe: RecipeResponseDTO?
    let variations: [Variant]?

    enum CodingKeys: String, CodingKey {
        case name, image, bodyTitle, diy, customize, kitCost, stackSize,
             buy, sell, hhaBasePoints, size, exchangePrice, exchangeCurrency,
             source, sourceNotes, seasonEvent, seasonEventExclusive,
             villagerEquippable, foodPower, lightingType, catalog, versionAdded,
             unlocked, filename, translations, colors, concepts, recipe, variations
        case internalID = "internalId"
        case uniqueEntryID = "uniqueEntryId"
    }
}

extension ToolsResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .tools,
            image: image ?? variations?.first?.image,
            diy: diy,
            buy: buy,
            sell: sell ?? -1,
            exchangePrice: variations?.first?.cyrusCustomizePrice ?? recipe?.exchangePrice,
            exchangeCurrency: .nookMiles,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            internalId: internalID,
            translations: translations,
            colors: colors ?? variations?.first?.colors ?? [],
            concepts: concepts ?? variations?.first?.concepts ?? [],
            recipe: recipe,
            bodyTitle: bodyTitle,
            catalog: catalog,
            variations: variations,
            bodyCustomize: customize,
            hhaBasePoints: hhaBasePoints
        )
    }
}
