//
//  BugResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - BugResponseDTO
struct BugResponseDTO: Codable, APIResponse {
    let num: Int
    let name: String
    let iconImage: String
    let critterpediaImage: String
    let furnitureImage: String
    let sell: Int
    let whereHow: String
    let weather: Weather
    let totalCatchesToUnlock: Int
    let spawnRates: String
    let size: Size
    let surface: Bool
    let description, catchPhrase: [String]
    let hhaBasePoints: Int
    let iconFilename: String
    let critterpediaFilename: String
    let furnitureFilename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let hemispheres: Hemispheres
    let colors: [Color]

}

enum Weather: String, Codable {
    case anyExceptRain = "Any except rain"
    case anyWeather = "Any weather"
    case rainOnly = "Rain only"
}
