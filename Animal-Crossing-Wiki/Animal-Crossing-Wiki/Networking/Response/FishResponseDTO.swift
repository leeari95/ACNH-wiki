//
//  FishResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - FishResponseDTO
struct FishResponseDTO: Codable, APIResponse {
    let num: Int
    let name: String
    let iconImage: String
    let critterpediaImage: String
    let furnitureImage: String
    let sell: Int
    let whereHow: String
    let shadow: Shadow
    let catchDifficulty: CatchDifficulty
    let vision: Vision
    let totalCatchesToUnlock: Int
    let spawnRates: String
    let size: Size
    let surface: Bool
    let description: [String]
    let catchPhrase: [String]
    let hhaBasePoints: Int
    let lightingType: LightingType?
    let iconFilename: String
    let critterpediaFilename: String
    let furnitureFilename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let hemispheres: Hemispheres
    let colors: [Color]
}

enum CatchDifficulty: String, Codable {
    case easy = "Easy"
    case hard = "Hard"
    case medium = "Medium"
    case veryEasy = "Very Easy"
    case veryHard = "Very Hard"
}

// MARK: - Hemispheres
struct Hemispheres: Codable {
    let north: EmergenceInfo
    let south: EmergenceInfo
}

// MARK: - North
struct EmergenceInfo: Codable {
    let time: [String]
    let months: [String]
    let monthsArray: [Int]
}

enum LightingType: String, Codable {
    case emission = "Emission"
    case fluorescent = "Fluorescent"
    case candle = "Candle"
    case monitor = "Monitor"
    case spotlight = "Spotlight"
}

enum Shadow: String, Codable {
    case large = "Large"
    case long = "Long"
    case medium = "Medium"
    case small = "Small"
    case xLarge = "X-Large"
    case xLargeWFin = "X-Large w/Fin"
    case xSmall = "X-Small"
    case xxLarge = "XX-Large"
}

enum Size: String, Codable {
    case the05X1 = "0.5x1"
    case the1X05 = "1x0.5"
    case the1X1 = "1x1"
    case the1X15 = "1x1.5"
    case the1X2 = "1x2"
    case the15X15 = "1.5x1.5"
    case the2X05 = "2x0.5"
    case the2X1 = "2x1"
    case the2X2 = "2x2"
    case the2X15 = "2x1.5"
    case the3X1 = "3x1"
    case the3X2 = "3x2"
    case the3X3 = "3x3"
    case the4X3 = "4x3"
    case the4X4 = "4x4"
    case the5X5 = "5x5"
}

enum Vision: String, Codable {
    case medium = "Medium"
    case narrow = "Narrow"
    case veryNarrow = "Very Narrow"
    case veryWide = "Very Wide"
    case wide = "Wide"
}

extension FishResponseDTO {
    func toDomain() -> Item {
        return Item(
            name: self.name,
            category: .fishes,
            iconImage: self.iconImage,
            critterpediaImage: self.critterpediaImage,
            furnitureImage: self.furnitureImage,
            sell: self.sell,
            whereHow: self.whereHow,
            shadow: self.shadow,
            catchDifficulty: self.catchDifficulty,
            vision: self.vision,
            translations: self.translations,
            hemispheres: self.hemispheres,
            colors: self.colors
        )
    }
}

extension Item {
    
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
}
