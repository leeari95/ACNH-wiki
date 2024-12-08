//
//  GyroidsResponseDTO.swift
//  ACNH-wiki
//
//  Created by Ari on 11/15/24.
//

import Foundation

// MARK: - GyroidsResponseDTO
struct GyroidsResponseDTO: Decodable {
    let image: String?
    let name: String
    let diy: Bool
    let patternCustomize: Bool
    let kitCost: Int?
    let size: Size
    let sourceNotes: [String]?
    let versionAdded: String
    let interact: Bool
    let tag: String
    let outdoor: Bool
    let lightingType: String?
    let catalog: Catalog
    let bodyCustomize: Bool
    let buy: Int
    let sell: Int
    let translations: Translations
    let source: [String]
    let hhaBasePoints: Int
    let unlocked: Bool
    let variations: [Variant]?
    let soundType: SoundType?
    let filename: String?
    let internalId: Int?
    let uniqueEntryID: String?
    let colors: [Color]?

    enum CodingKeys: String, CodingKey {
        case image, name, diy, patternCustomize, kitCost, size, sourceNotes, versionAdded,
             interact, tag, outdoor, lightingType, catalog, bodyCustomize, buy,
             sell, translations, source, hhaBasePoints, unlocked, variations,
             soundType, filename, colors, internalId
        case uniqueEntryID = "uniqueEntryId"
    }
}

// MARK: - SoundType
enum SoundType: String, Decodable {
    case crash = "Crash"
    case drumSet = "Drum set"
    case hiHat = "Hi-hat"
    case kick = "Kick"
    case melody = "Melody"
    case snare = "Snare"
    
    var localized: String { rawValue.localized }
}

// MARK: - DomainConvertible
extension Item {
    init(
        name: String,
        category: Category,
        buy: Int,
        sell: Int,
        exchangePrice: Int,
        diy: Bool,
        internalId: Int?,
        translations: Translations,
        colors: [Color],
        image: String,
        sources: [String],
        sourceNotes: [String]?,
        catalog: Catalog,
        variations: [Variant]?,
        bodyCustomize: Bool,
        hhaBasePoints: Int,
        soundType: SoundType?
    ) {
        self.name = name
        self.category = category
        self.buy = buy
        self.sell = sell
        self.exchangePrice = exchangePrice
        self.diy = diy
        self.internalId = internalId
        self.translations = translations
        self.colors = colors
        self.image = image
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.catalog = catalog
        self.variations = variations
        self.bodyCustomize = bodyCustomize
        self.hhaBasePoints = hhaBasePoints
        self.soundType = soundType
    }
}

extension GyroidsResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .gyroids,
            buy: -1,
            sell: sell,
            exchangePrice: variations?.first?.cyrusCustomizePrice ?? 0,
            diy: false,
            internalId: internalId,
            translations: translations,
            colors: colors ?? variations?.first?.colors ?? [],
            image: variations?.first?.image ?? image ?? "",
            sources: source,
            sourceNotes: sourceNotes,
            catalog: catalog,
            variations: variations,
            bodyCustomize: bodyCustomize,
            hhaBasePoints: hhaBasePoints,
            soundType: soundType ?? variations?.first?.soundType
        )
    }
}
