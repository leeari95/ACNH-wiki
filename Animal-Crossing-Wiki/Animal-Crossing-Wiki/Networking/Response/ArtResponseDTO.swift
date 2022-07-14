//
//  ArtResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - ArtResponseDTO
struct ArtResponseDTO: Codable, APIResponse {
    let name: String
    let image: String
    let highResTexture: String?
    let genuine: Bool
    let category: ArtCategory
    let buy: Int
    let sell: Int?
    let size: Size
    let realArtworkTitle, artist: String
    let description: [String]
    let source: [String]
    let hhaBasePoints: Int
    let interact: Bool
    let tag: String
    let unlocked: Bool
    let filename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let colors: [Color]
    let concepts: [Concept]
}

enum ArtCategory: String, Codable {
    case housewares = "Housewares"
    case miscellaneous = "Miscellaneous"
    case wallMounted = "Wall-mounted"
}

enum Concept: String, Codable {
    case ancient = "ancient"
    case cityLife = "city life"
    case european = "European"
    case expensive = "expensive"
    case harmonious = "harmonious"
    case horror = "horror"
    case resort = "resort"
    case amusementPark = "amusement park"
    case apparelShop = "apparel shop"
    case arcade = "arcade"
    case bathroom = "bathroom"
    case café = "café"
    case childSRoom = "child's room"
    case concert = "concert"
    case constructionSite = "construction site"
    case den = "den"
    case facility = "facility"
    case fancy = "fancy"
    case fantasy = "fantasy"
    case fitness = "fitness"
    case freezingCold = "freezing cold"
    case garden = "garden"
    case heritage = "heritage"
    case hospital = "hospital"
    case kitchen = "kitchen"
    case lab = "lab"
    case livingRoom = "living room"
    case local = "local"
    case music = "music"
    case nature = "nature"
    case ocean = "ocean"
    case office = "office"
    case outdoors = "outdoors"
    case park = "park"
    case party = "party"
    case publicBath = "public bath"
    case restaurant = "restaurant"
    case retro = "retro"
    case school = "school"
    case sciFi = "sci-fi"
    case shop = "shop"
    case space = "space"
    case sports = "sports"
    case stylish = "stylish"
    case supermarket = "supermarket"
    case workshop = "workshop"
}

extension ArtResponseDTO {
    func toDomain() -> Item {
        return Item(
            name: self.name,
            category: .art,
            image: self.image,
            highResTexture: self.highResTexture,
            genuine: self.genuine,
            artCategory: self.category,
            buy: self.buy,
            sell: self.sell ?? 0,
            size: self.size,
            source: self.source.first ?? "",
            tag: self.tag,
            translations: self.translations,
            colors: self.colors,
            concepts: self.concepts,
            keyword: [
                .color: self.colors.map { $0.rawValue },
                .concept: self.concepts.map { $0.rawValue }
            ]
        )
    }
}
