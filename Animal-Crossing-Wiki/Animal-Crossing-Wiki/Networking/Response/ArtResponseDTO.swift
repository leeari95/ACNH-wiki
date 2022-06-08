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
    let hhaBasePoints: Int
    let interact: Bool
    let tag: Tag
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
}

enum Tag: String, Codable {
    case picture = "Picture"
    case sculpture = "Sculpture"
}

extension ArtResponseDTO {
    func toDomain() -> Art {
        let isFake = self.filename.contains("Fake")
        return Art(
            name: self.name,
            image: self.image,
            highResTexture: self.highResTexture,
            genuine: self.genuine,
            artCategory: self.category,
            buy: self.buy,
            sell: self.sell ?? 0,
            size: self.size,
            tag: self.tag,
            unlocked: self.unlocked,
            isFake: isFake,
            translations: self.translations,
            colors: self.colors,
            concepts: self.concepts
        )
    }
}
