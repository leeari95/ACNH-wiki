//
//  FishResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import AnyCodable

// MARK: - FishResponseDTO
struct FishResponseDTO: Codable, APIResponse {
    let num: Int
    let name: String
    let iconImage, critterpediaImage, furnitureImage: String
    let sell: Int
    let whereHow: WhereHow
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
    let iconFilename, critterpediaFilename, furnitureFilename: String
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
    let timeArray: AnyCodable
    let months: [String]
    let monthsArray: [Int]
}

enum LightingType: String, Codable {
    case emission = "Emission"
    case fluorescent = "Fluorescent"
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
    case the1X1 = "1x1"
    case the1X2 = "1x2"
    case the2X1 = "2x1"
    case the2X15 = "2x1.5"
    case the2X2 = "2x2"
    case the3X2 = "3x2"
}

enum Vision: String, Codable {
    case medium = "Medium"
    case narrow = "Narrow"
    case veryNarrow = "Very Narrow"
    case veryWide = "Very Wide"
    case wide = "Wide"
}

enum WhereHow: String, Codable {
    case pier = "Pier"
    case pond = "Pond"
    case river = "River"
    case riverClifftop = "River (clifftop)"
    case riverMouth = "River (mouth)"
    case sea = "Sea"
    case seaRainyDays = "Sea (rainy days)"
}
