//
//  SeaCreaturesResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import ACNHCore

// MARK: - SeaCreaturesResponseDTO
struct SeaCreaturesResponseDTO: Decodable {
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

extension SeaCreaturesResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: self.name,
            category: .seaCreatures,
            iconImage: self.iconImage,
            critterpediaImage: self.critterpediaImage,
            furnitureImage: self.furnitureImage,
            sell: self.sell,
            shadow: self.shadow,
            movementSpeed: self.movementSpeed,
            spawnRates: self.spawnRates,
            size: self.size,
            translations: self.translations,
            hemispheres: self.hemispheres,
            colors: self.colors ?? []
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
        self.genuine = true
    }
}
