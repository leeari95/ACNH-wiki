//
//  CeilingDecorResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/16.
//

import Foundation
import ACNHCore

struct CeilingDecorResponseDTO: Decodable {
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
    let recipe: RecipeResponseDTO?
}

extension CeilingDecorResponseDTO: DomainConvertible {
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

extension Item {
    init(
        name: String,
        category: Category,
        image: String?,
        diy: Bool,
        bodyCustomize: Bool,
        patternCustomize: Bool,
        buy: Int,
        sell: Int,
        size: Size,
        exchangePrice: Int?,
        exchangeCurrency: ExchangeCurrency?,
        sources: [String],
        hhaBasePoints: Int?,
        hhaCategory: HhaCategory?,
        tag: String,
        catalog: Catalog?,
        internalId: Int?,
        translations: Translations,
        colors: [Color]?,
        concepts: [Concept]?,
        set: String?,
        series: String?,
        recipe: RecipeResponseDTO?,
        seriesTranslations: Translations?,
        variations: [Variant]?
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.diy = diy
        self.bodyCustomize = bodyCustomize
        self.patternCustomize = patternCustomize
        self.buy = buy
        self.sell = sell
        self.size = size
        self.exchangePrice = exchangePrice
        self.exchangeCurrency = exchangeCurrency
        self.sources = sources
        self.hhaBasePoints = hhaBasePoints
        self.hhaCategory = hhaCategory
        self.tag = tag
        self.catalog = catalog
        self.internalId = internalId
        self.translations = translations
        self.colors = colors ?? []
        self.concepts = concepts
        self.set = set
        self.series = series
        self.recipe = recipe
        self.seriesTranslations = seriesTranslations
        self.variations = variations
        self.genuine = true
    }
}
