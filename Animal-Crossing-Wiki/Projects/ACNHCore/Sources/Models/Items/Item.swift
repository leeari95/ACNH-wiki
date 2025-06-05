//
//  Item.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

public struct Item {
    public let name: String
    public let category: Category
    public let sell: Int
    public let translations: Translations
    public let colors: [Color]

    public var image: String?
    public var iconImage: String?
    public var critterpediaImage: String?
    public var furnitureImage: String?
    public var hemispheres: Hemispheres?
    public var whereHow: String?
    public var weather: Weather?
    public var spawnRates: String?
    public var catchDifficulty: CatchDifficulty?
    public var vision: Vision?
    public var shadow: Shadow?
    public var movementSpeed: MovementSpeed?
    public var buy: Int?

    public var museum: Museum?

    public var highResTexture: String?
    public var genuine: Bool?
    public var fakeDifferences: Translations?
    public var artCategory: ArtCategory?
    public var size: Size?
    public var source: String?
    public var tag: String?
    public var concepts: [Concept]?

    public var variation: String?
    public var bodyTitle: String?
    public var pattern: String?
    public var patternTitle: String?
    public var diy: Bool?
    public var bodyCustomize: Bool?
    public var patternCustomize: Bool?
    public var exchangePrice: Int?
    public var exchangeCurrency: ExchangeCurrency?
    public var sources: [String]?
    public var sourceNotes: [String]?
    public var seasonEvent: String?
    public var hhaCategory: HhaCategory?
    public var hhaBasePoints: Int?
    public var outdoor: Bool?
    public var speakerType: String?
    public var lightingType: LightingType?
    public var catalog: Catalog?
    public var internalId: Int?
    public var set: String?
    public var series: String?
    public var recipe: RecipeResponseDTO?
    public var seriesTranslations: Translations?
    public var variations: [Variant]?

    public var foodPower: Int?
    public var doorDeco: Bool?

    public var musicURL: String?
    public var themes: [String]?
    public var styles: [Style]?
    
    public var soundType: SoundType?
}

public extension Item {

    public var keyword: [String] {
        public var list = colors.map { $0.rawValue }
        + (concepts?.map { $0.rawValue } ?? [])
        + (themes ?? [])
        + (styles?.map { $0.rawValue } ?? [])
        if let tag = tag, !list.contains(tag.lowercased()) {
            list.append(tag)
        }
        return list
    }

    public var canExchangeNookMiles: Bool {
        exchangeCurrency == .nookMiles || variations?.first?.exchangeCurrency == .nookMiles
    }

    public var canExchangeNookPoints: Bool {
        exchangeCurrency == .nookPoints || variations?.first?.exchangeCurrency == .nookPoints
    }

    public var canExchangePoki: Bool {
        exchangeCurrency == .poki || variations?.first?.exchangeCurrency == .poki
    }

    public var isCritters: Bool {
        Category.critters.contains(category)
    }

    public var variationsWithColor: [Variant] {
        variations?.filter { $0.variantId.suffix(2) == ("_0") } ?? []
    }

    public var variationsWithPattern: [Variant] {
        variations?.filter { $0.pattern != nil } ?? []
    }
}

public extension Item: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name && lhs.genuine  == rhs.genuine
    }
}

public extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(genuine)
    }
}
