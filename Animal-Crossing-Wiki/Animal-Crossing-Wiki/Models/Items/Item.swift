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
    var sources: [String]?
    var sourceNotes: [String]?
    var seasonEvent: String?
    var hhaCategory: HhaCategory?
    var hhaBasePoints: Int?
    var outdoor: Bool?
    var speakerType: String?
    var lightingType: LightingType?
    var catalog: Catalog?
    var internalId: Int?
    var set: String?
    var series: String?
    var recipe: RecipeResponseDTO?
    var seriesTranslations: Translations?
    var variations: [Variant]?
    
    var foodPower: Int?
    var doorDeco: Bool?
    
    var musicURL: String?
}

extension Item {

    var keyword: [String] {
        var list = colors.map { $0.rawValue } + (concepts?.map { $0.rawValue } ?? [])
        if let tag = tag, !list.contains(tag.lowercased()) {
            list.append(tag)
        }
        return list
    }
    
    var canExchangeNookMiles: Bool {
        exchangeCurrency == .nookMiles || variations?.first?.exchangeCurrency == .nookMiles
    }
    
    var canExchangeNookPoints: Bool {
        exchangeCurrency == .nookPoints || variations?.first?.exchangeCurrency == .nookPoints
    }
    
    var canExchangePoki: Bool {
        exchangeCurrency == .poki || variations?.first?.exchangeCurrency == .poki
    }
    
    var isCritters: Bool {
        Category.critters.contains(category)
    }
    
    var variationsWithColor: [Variant] {
        variations?.filter { $0.variantId.suffix(2) == ("_0") } ?? []
    }
    
    var variationsWithPattern: [Variant] {
        variations?.filter { $0.pattern != nil } ?? []
    }
}

extension Item: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name && lhs.genuine  == rhs.genuine
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(genuine)
    }
}
