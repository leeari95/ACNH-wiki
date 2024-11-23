//
//  FencingResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/23.
//

import Foundation

struct FencingResponseDTO: Decodable {
    let name: String
    let image: String?
    let bodyTitle: String?
    let diy, customize: Bool
    let kitCost: Int?
    let kitType: String?
    let cyrusCustomizePrice: Int?
    let stackSize: Int?
    let buy: Int
    let sell: Int
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let catalog: Catalog
    let versionAdded: String
    let unlocked: Bool
    let filename: String?
    let variantId: String?
    let internalId: Int?
    let uniqueEntryId: String?
    let translations: Translations
    let recipe: RecipeResponseDTO
    let variations: [Variant]?
}

extension Item {
    init(
        name: String,
        category: Category,
        image: String?,
        diy: Bool,
        buy: Int,
        sell: Int,
        exchangePrice: Int?,
        exchangeCurrency: ExchangeCurrency?,
        sources: [String],
        sourceNotes: [String]?,
        seasonEvent: String?,
        internalId: Int?,
        translations: Translations,
        colors: [Color] = [],
        recipe: RecipeResponseDTO?,
        bodyTitle: String?,
        catalog: Catalog?,
        variations: [Variant]?,
        bodyCustomize: Bool
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.diy = diy
        self.buy = buy
        self.sell = sell
        self.exchangePrice = exchangePrice
        self.exchangeCurrency = exchangeCurrency
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.seasonEvent = seasonEvent
        self.internalId = internalId
        self.translations = translations
        self.colors = colors
        self.recipe = recipe
        self.bodyTitle = bodyTitle
        self.catalog = catalog
        self.variations = variations
        self.genuine = true
        self.patternCustomize = false
        self.bodyCustomize = bodyCustomize
    }
}

extension FencingResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .fencing,
            image: image ?? variations?.first?.image,
            diy: diy,
            buy: buy,
            sell: sell,
            exchangePrice: cyrusCustomizePrice ?? variations?.first?.cyrusCustomizePrice ?? recipe.exchangePrice,
            exchangeCurrency: .nookMiles,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            internalId: internalId,
            translations: translations,
            recipe: recipe,
            bodyTitle: bodyTitle,
            catalog: catalog,
            variations: variations,
            bodyCustomize: customize
        )
    }
}
