//
//  BugResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation
import ACNHCore

// MARK: - BugResponseDTO
struct BugResponseDTO: Decodable {
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

extension BugResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: self.name,
            category: .bugs,
            iconImage: self.iconImage,
            critterpediaImage: self.critterpediaImage,
            furnitureImage: self.furnitureImage,
            sell: self.sell,
            whereHow: self.whereHow,
            weather: self.weather,
            spawnRates: self.spawnRates,
            size: self.size,
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
        weather: Weather,
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
        self.whereHow = whereHow
        self.weather = weather
        self.spawnRates = spawnRates
        self.size = size
        self.translations = translations
        self.hemispheres = hemispheres
        self.colors = colors
        self.genuine = true
    }

}
