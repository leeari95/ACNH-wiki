//
//  RecipeResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/20.
//

import Foundation

// MARK: - Recipe
struct RecipeResponseDTO: Codable {
    let name: String
    let image: String
    let imageSh: String?
    let buy: Int
    let sell: Int?
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let versionAdded: String
    let unlocked: Bool
    let recipesToUnlock: Int
    let category: String
    let craftedItemInternalId: Int
    let cardColor: String?
    let diyIconFilename: String
    let diyIconFilenameSh: String?
    let serialId: Int
    let internalId: Int
    let translations: Translations?
    let materials: [String: Int]
    let materialsTranslations: [String: Translations?]
}

extension RecipeResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .recipes,
            image: image,
            buy: buy,
            sell: sell ?? -1,
            exchangePrice: exchangePrice,
            exchangeCurrency: exchangeCurrency,
            sources: source,
            sourceNotes: sourceNotes,
            internalId: internalId,
            translations: translations,
            recipe: self
        )
    }
}

extension Item {
    init(
        name: String,
        category: Category,
        image: String?,
        buy: Int,
        sell: Int,
        exchangePrice: Int?,
        exchangeCurrency: ExchangeCurrency?,
        sources: [String],
        sourceNotes: [String]?,
        internalId: Int?,
        translations: Translations?,
        recipe: RecipeResponseDTO?
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.buy = buy
        self.sell = sell
        self.exchangePrice = exchangePrice
        self.exchangeCurrency = exchangeCurrency
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.internalId = internalId
        self.translations = translations ?? Translations([:])
        self.recipe = recipe
        self.genuine = true
        self.colors = []
    }
}
