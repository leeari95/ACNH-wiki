//
//  PhotosResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/17.
//

import Foundation

// MARK: - WelcomeElement
struct PhotosResponseDTO: Codable {
    let sourceSheet: String
    let name: String
    let diy: Bool
    let kitCost: Int
    let size: Size
    let versionAdded: String
    let bodyTitle: String
    let buy, sell: Int
    let customize: Bool
    let translations: Translations
    let source: [String]
    let hhaBasePoints: Int
    let unlocked: Bool
    let variations: [Variant]
}

extension PhotosResponseDTO {
    
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .photos,
            sell: sell,
            translations: translations,
            colors: variations.first?.colors ?? [],
            diy: diy,
            size: size,
            image: variations.first?.image ?? "",
            bodyTitle: bodyTitle,
            sources: source,
            bodyCustomize: customize,
            hhaBasePoints: hhaBasePoints,
            variations: variations
        )
    }
}

extension Item {
    init(
        name: String,
        category: Category,
        sell: Int,
        translations: Translations,
        colors: [Color],
        diy: Bool,
        size: Size,
        image: String?,
        bodyTitle: String,
        sources: [String],
        bodyCustomize: Bool,
        hhaBasePoints: Int,
        variations: [Variant]
    ) {
        self.name = name
        self.category = category
        self.sell = sell
        self.translations = translations
        self.colors = colors
        self.diy = diy
        self.size = size
        self.image = image
        self.bodyTitle = bodyTitle
        self.sources = sources
        self.bodyCustomize = bodyCustomize
        self.hhaBasePoints = hhaBasePoints
        self.variations = variations
    }
}

/*
enum Source: String, Codable {
    case blathers = "Blathers"
    case checkToyDayStockingsTheDayAfterToyDay = "Check Toy Day stockings the day after Toy Day"
    case highFriendship = "High Friendship"
    case lottie = "Lottie"
    case niko = "Niko"
    case nookLink = "NookLink"
    case rover = "Rover"
    case wardell = "Wardell"
}

enum SourceSheet: String, Codable {
    case itemVariantNames = "Item Variant Names"
    case photos = "Photos"
}

enum Concept: String, Codable {
    case childSRoom = "child's room"
    case livingRoom = "living room"
}

enum ExchangeCurrency: String, Codable {
    case nookPoints = "Nook Points"
}

enum SeasonEvent: String, Codable {
    case happyHomeParadise = "Happy Home Paradise"
    case mayDay = "May Day"
    case toyDayDayAfter = "Toy Day (day after)"
}

enum VariantID: String, Codable {
    case the0_0 = "0_0"
    case the1_0 = "1_0"
    case the2_0 = "2_0"
    case the3_0 = "3_0"
    case the4_0 = "4_0"
    case the5_0 = "5_0"
    case the6_0 = "6_0"
    case the7_0 = "7_0"
}

enum VariationEnum: String, Codable {
    case colorful = "Colorful"
    case darkWood = "Dark wood"
    case gold = "Gold"
    case naturalWood = "Natural wood"
    case pastel = "Pastel"
    case pop = "Pop"
    case silver = "Silver"
    case white = "White"
}

enum VersionAdded: String, Codable {
    case the100 = "1.0.0"
    case the1100 = "1.10.0"
    case the160 = "1.6.0"
    case the190 = "1.9.0"
    case the200 = "2.0.0"
}
*/
