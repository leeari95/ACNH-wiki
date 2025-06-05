//
//  TopsResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/18.
//

import Foundation
import ACNHCore

struct TopsResponseDTO: Decodable {
    let sourceSheet: String
    let name: String
    let closetImage, storageImage: String?
    let variation: String?
    let diy: Bool
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
    let seasonalAvailability: String
    let seasonality: String?
    let mannequinSeason: String?
    let sortOrder: Int?
    let villagerEquippable: Bool
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String?
    let clothGroupId, internalId: Int?
    let uniqueEntryId: String?
    let themesTranslations: [String: Translations]?
    let translations: Translations
    let colors: [Color]?
    let styles: [Style]
    let themes: [Theme]
    let recipe: RecipeResponseDTO?
    let variations: [WardrobeVariat]?
}

enum Theme: String, Codable {
    case everyday, comfy, outdoorsy, formal, vacation, work, party, theatrical, sporty, goth
    case fairyTale = "fairy tale"
}

struct WardrobeVariat: Decodable {
    let closetImage: String?
    let storageImage: String
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let seasonality: String
    let mannequinSeason: String?
    let sortOrder: Int
    let filename: String
    let clothGroupId, internalId: Int
    let uniqueEntryId: String
    let variantTranslations: Translations
    let colors: [Color]

    func toVariat() -> Variant {
        return .init(
            image: closetImage ?? storageImage,
            variation: nil,
            pattern: nil,
            patternTitle: nil,
            kitType: nil,
            cyrusCustomizePrice: -1,
            surface: nil,
            exchangePrice: exchangePrice,
            exchangeCurrency: exchangeCurrency,
            seasonEvent: seasonEvent,
            seasonEventExclusive: seasonEventExclusive,
            hhaCategory: nil,
            filename: filename,
            variantId: "1_0_0",
            internalId: internalId,
            variantTranslations: variantTranslations,
            colors: colors,
            concepts: [],
            patternTranslations: nil,
            soundType: nil
        )
    }
}

extension TopsResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .tops,
            image: closetImage ?? variations?.first?.closetImage,
            diy: diy,
            buy: buy,
            sell: sell ?? -1,
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
            recipe: recipe,
            variations: variations?.map { $0.toVariat() }
        )
    }
}

extension Item {
    init(
        name: String,
        category: Category,
        image: String?,
        diy: Bool,
        buy: Int?,
        sell: Int,
        size: Size,
        exchangePrice: Int?,
        exchangeCurrency: ExchangeCurrency?,
        sources: [String],
        sourceNotes: [String]?,
        seasonEvent: String?,
        hhaBasePoints: Int?,
        catalog: Catalog?,
        internalId: Int?,
        translations: Translations,
        colors: [Color]?,
        themes: [String]?,
        styles: [Style],
        recipe: RecipeResponseDTO?,
        variations: [Variant]?
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.diy = diy
        self.buy = buy
        self.sell = sell
        self.size = size
        self.exchangePrice = exchangePrice
        self.exchangeCurrency = exchangeCurrency
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.seasonEvent = seasonEvent
        self.hhaBasePoints = hhaBasePoints
        self.catalog = catalog
        self.internalId = internalId
        self.translations = translations
        self.colors = colors ?? []
        self.themes = themes
        self.styles = styles
        self.recipe = recipe
        self.variations = variations
        self.genuine = true
    }
}
