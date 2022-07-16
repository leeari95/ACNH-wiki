//
//  HousewaresResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import Foundation

struct HousewaresResponseDTO: Codable, APIResponse {

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
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String?
    let variantId: String?
    let internalId: Int?
    let uniqueEntryId: String?
    let translations: Translations
    let colors: [Color]?
    let concepts: [Concept]?
    let set: String?
    let series: String?
    let recipe: Recipe?
    let seriesTranslations: Translations?
    let variations: [Variant]?

}

struct FurnitureTranslations: Codable {
    let id: Int
    let eUde, eUen, eUit, eUnl: String
    let eUru, eUfr, eUes, uSen: String
    let uSfr, uSes, jPja, kRko: String
    let tWzh, cNzh: String
    
    enum LanguageCode: String {
        case de, en, it, nl, ru, fr, es, ja, ko, zh
    }
    
    func localizedName() -> String {
        guard let code = Locale.current.languageCode, let languageCode = LanguageCode(rawValue: code) else {
            return uSen
        }
        switch languageCode {
        case .de: return eUde
        case .en: return uSen
        case .it: return eUit
        case .nl: return eUnl
        case .ru: return eUru
        case .fr: return eUfr
        case .es: return eUes
        case .ja: return jPja
        case .ko: return kRko
        case .zh: return cNzh
        }
    }
}

enum Catalog: String, Codable {
    case forSale = "For sale"
    case notForSale = "Not for sale"
    case seasonal = "Seasonal"
}

enum ExchangeCurrency: String, Codable {
    case heartCrystals = "Heart Crystals"
    case nookMiles = "Nook Miles"
    case poki = "Poki"
    case nookPoints = "Nook Points"
    case bells = "Bells"
}

enum HhaCategory: String, Codable {
    case ac = "AC"
    case appliance = "Appliance"
    case audio = "Audio"
    case clock = "Clock"
    case doll = "Doll"
    case dresser = "Dresser"
    case kitchen = "Kitchen"
    case lighting = "Lighting"
    case musicalInstrument = "MusicalInstrument"
    case pet = "Pet"
    case plant = "Plant"
    case smallGoods = "SmallGoods"
    case trash = "Trash"
    case tv = "TV"
    case food = "Food"
}

enum InteractUnion: Codable {
    case bool(Bool)
    case enumeration(InteractEnum)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let element = try? container.decode(Bool.self) {
            self = .bool(element)
            return
        }
        if let element = try? container.decode(InteractEnum.self) {
            self = .enumeration(element)
            return
        }
        throw DecodingError.typeMismatch(
            InteractUnion.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for InteractUnion")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let element):
            try container.encode(element)
        case .enumeration(let element):
            try container.encode(element)
        }
    }
}

enum InteractEnum: String, Codable {
    case bed = "Bed"
    case chair = "Chair"
    case kitchenware = "Kitchenware"
    case mirror = "Mirror"
    case musicPlayer = "Music Player"
    case musicalInstrument = "Musical Instrument"
    case storage = "Storage"
    case toilet = "Toilet"
    case trash = "Trash"
    case tv = "TV"
    case wardrobe = "Wardrobe"
    case workbench = "Workbench"
}

// MARK: - Recipe
struct Recipe: Codable {
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
    let materials: [String: Int]
    let materialsTranslations: [String: Translations?]
}

// MARK: - Variation
struct Variant: Codable {
    let image: String
    let variation: String?
    let pattern: String?
    let patternTitle: String?
    let kitType: Kit?
    let cyrusCustomizePrice: Int
    let surface: Bool?
    let exchangePrice: Int?
    let exchangeCurrency: ExchangeCurrency?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let hhaCategory: HhaCategory?
    let filename: String
    let variantId: String
    let internalId: Int
    let variantTranslations: Translations?
    let colors: [Color]
    let concepts: [Concept]
    let patternTranslations: Translations?
    
    func toKeyword() -> [String] {
        return colors.map { $0.rawValue } + concepts.map { $0.rawValue }
    }
}

enum Kit: String, Codable {
    case normal = "Normal"
    case pumpkin = "Pumpkin"
    case rainbowFeather = "Rainbow feather"
}

extension HousewaresResponseDTO {
    func toDomain() -> Item {
        let image = image ?? variations?.first?.image
        return Item(
            name: name,
            category: .housewares,
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
        sourceNotes: [String]?,
        seasonEvent: String?,
        hhaBasePoints: Int? = nil,
        hhaCategory: HhaCategory?,
        tag: String,
        speakerType: String? = nil,
        lightingType: LightingType? = nil,
        catalog: Catalog?,
        internalId: Int? = nil,
        translations: Translations,
        colors: [Color]?,
        concepts: [Concept]?,
        set: String?,
        series: String?,
        recipe: Recipe?,
        seriesTranslations: Translations?,
        variations: [Variant]?,
        foodPower: Int? = nil,
        doorDeco: Bool? = nil
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
        self.sourceNotes = sourceNotes
        self.seasonEvent = seasonEvent
        self.hhaBasePoints = hhaBasePoints
        self.hhaCategory = hhaCategory
        self.tag = tag
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
        self.foodPower = foodPower
        self.doorDeco = doorDeco
    }
}
