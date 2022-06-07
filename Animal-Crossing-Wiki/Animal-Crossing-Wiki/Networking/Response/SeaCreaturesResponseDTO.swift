//
//  SeaCreaturesResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - SeaCreaturesResponseDTO
struct SeaCreaturesResponseDTO: Codable, APIResponse {
    let num: Int
    let name: String
    let iconImage: String
    let critterpediaImage: String
    let furnitureImage: String
    let sell: Int
    let shadow: Shadow
    let movementSpeed: MovementSpeed
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
    let unlocked: Bool
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let hemispheres: Hemispheres
    let colors: [Color]?
}

enum MovementSpeed: String, Codable {
    case fast = "Fast"
    case medium = "Medium"
    case slow = "Slow"
    case stationary = "Stationary"
    case veryFast = "Very fast"
    case verySlow = "Very slow"
}
