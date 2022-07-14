//
//  Item.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct Item {
    let name: String
    let category: Category
    let sell: Int
    let translations: Translations
    let colors: [Color]
    
    var image: String?
    var iconImage: String?
    var critterpediaImage: String?
    var furnitureImage: String?
    var hemispheres: Hemispheres?
    var whereHow: String?
    var weather: Weather?
    var spawnRates: String?
    var catchDifficulty: CatchDifficulty?
    var vision: Vision?
    var shadow: Shadow?
    var movementSpeed: MovementSpeed?
    var buy: Int?
    
    var museum: Museum?
    
    var highResTexture: String?
    var genuine: Bool?
    var artCategory: ArtCategory?
    var size: Size?
    var source: String?
    var tag: String?
    var concepts: [Concept]?
    
    var variation: String?
    var bodyTitle: String?
    var pattern: String?
    var patternTitle: String?
    var diy: Bool?
    var bodyCustomize: Bool?
    var patternCustomize: Bool?
    var exchangePrice: Int?
    var exchangeCurrency: ExchangeCurrency?
    var sources: [Source]?
    var sourceNotes: [String]?
    var seasonEvent: String?
    var hhaCategory: HhaCategory?
    var outdoor: Bool?
    var speakerType: String?
    var lightingType: LightingType?
    var catalog: Catalog?
    var internalId: Int?
    var set: String?
    var series: String?
    var recipe: Recipe?
    var seriesTranslations: Translations?
    var variations: [Variant]?
}

extension Item {
    
    // Fish
    init(
        name: String,
        category: Category,
        iconImage: String,
        critterpediaImage: String,
        furnitureImage: String,
        sell: Int,
        whereHow: String,
        shadow: Shadow,
        catchDifficulty: CatchDifficulty,
        vision: Vision,
        translations: Translations,
        hemispheres: Hemispheres,
        colors: [Color]
    ) {
        self.name = name
        self.category = category
        self.iconImage = iconImage
        self.critterpediaImage = critterpediaImage
        self.furnitureImage = furnitureImage
        self.sell = sell
        self.whereHow = whereHow
        self.shadow = shadow
        self.catchDifficulty = catchDifficulty
        self.vision = vision
        self.translations = translations
        self.hemispheres = hemispheres
        self.colors = colors
    }
    
    // Fossils
    init(
        name: String,
        category: Category,
        image: String,
        buy: Int,
        sell: Int,
        size: Size,
        source: String,
        museum: Museum,
        translations: Translations,
        colors: [Color]
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.buy = buy
        self.sell = sell
        self.size = size
        self.source = source
        self.museum = museum
        self.translations = translations
        self.colors = colors
    }
    
    // bug
    init(
        name: String,
        category: Category,
        iconImage: String,
        critterpediaImage: String,
        furnitureImage: String,
        sell: Int,
        whereHow: String,
        weather: Weather,
        spawnRates: String,
        size: Size,
        translations: Translations,
        hemispheres: Hemispheres,
        colors: [Color]
    ) {
        self.name = name
        self.category = category
        self.iconImage = iconImage
        self.critterpediaImage = critterpediaImage
        self.furnitureImage = furnitureImage
        self.sell = sell
        self.whereHow = whereHow
        self.weather = weather
        self.spawnRates = spawnRates
        self.size = size
        self.translations = translations
        self.hemispheres = hemispheres
        self.colors = colors
    }
    
    // SeaCreatures
    init(
        name: String,
        category: Category,
        iconImage: String,
        critterpediaImage: String,
        furnitureImage: String,
        sell: Int,
        shadow: Shadow,
        movementSpeed: MovementSpeed,
        spawnRates: String,
        size: Size,
        translations: Translations,
        hemispheres: Hemispheres,
        colors: [Color]
    ) {
        self.name = name
        self.category = category
        self.iconImage = iconImage
        self.critterpediaImage = critterpediaImage
        self.furnitureImage = furnitureImage
        self.sell = sell
        self.shadow = shadow
        self.movementSpeed = movementSpeed
        self.spawnRates = spawnRates
        self.size = size
        self.translations = translations
        self.hemispheres = hemispheres
        self.colors = colors
    }
    
    // Art
    init(
        name: String,
        category: Category,
        image: String,
        highResTexture: String?,
        genuine: Bool,
        artCategory: ArtCategory,
        buy: Int,
        sell: Int,
        size: Size,
        source: String,
        tag: String,
        translations: Translations,
        colors: [Color],
        concepts: [Concept]
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.highResTexture = highResTexture
        self.genuine = genuine
        self.artCategory = artCategory
        self.buy = buy
        self.sell = sell
        self.size = size
        self.source = source
        self.tag = tag
        self.translations = translations
        self.colors = colors
        self.concepts = concepts
    }
    
    // Housewares
    init(
        name: String,
        category: Category,
        image: String?,
        variation: String?,
        bodyTitle: String?,
        pattern: String?,
        patternTitle: String?,
        diy: Bool,
        bodyCustomize: Bool,
        patternCustomize: Bool,
        buy: Int,
        sell: Int,
        size: Size,
        exchangePrice: Int?,
        exchangeCurrency: ExchangeCurrency?,
        sources: [Source],
        sourceNotes: [String]?,
        seasonEvent: String?,
        hhaCategory: HhaCategory?,
        tag: String,
        outdoor: Bool,
        speakerType: String?,
        lightingType: LightingType?,
        catalog: Catalog?,
        internalId: Int?,
        translations: Translations,
        colors: [Color]?,
        concepts: [Concept]?,
        set: String?,
        series: String?,
        recipe: Recipe?,
        seriesTranslations: Translations?,
        variations: [Variant]?
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.variation = variation
        self.bodyTitle = bodyTitle
        self.pattern = pattern
        self.patternTitle = patternTitle
        self.diy = diy
        self.bodyCustomize = bodyCustomize
        self.patternCustomize = patternCustomize
        self.buy = buy
        self.sell = sell
        self.size = size
        self.exchangePrice = exchangePrice
        self.exchangeCurrency = exchangeCurrency
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.seasonEvent = seasonEvent
        self.hhaCategory = hhaCategory
        self.tag = tag
        self.outdoor = outdoor
        self.speakerType = speakerType
        self.lightingType = lightingType
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
    }
}

extension Item {

    var keyword: [String] {
        var list = colors.map { $0.rawValue } + (concepts?.map { $0.rawValue } ?? [])
        if let tag = tag, !list.contains(tag.lowercased()) {
            list.append(tag)
        }
        return list
    }
}
