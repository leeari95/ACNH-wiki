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

enum Concept: String, Codable, CaseIterable {
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
    
    static func transform(_ localizedString: String) -> String? {
        switch localizedString {
        case Concept.ancient.rawValue.localized: return Concept.ancient.rawValue
        case Concept.cityLife.rawValue.localized: return Concept.cityLife.rawValue
        case Concept.european.rawValue.localized: return Concept.european.rawValue
        case Concept.expensive.rawValue.localized: return Concept.expensive.rawValue
        case Concept.harmonious.rawValue.localized: return Concept.harmonious.rawValue
        case Concept.horror.rawValue.localized: return Concept.horror.rawValue
        case Concept.resort.rawValue.localized: return Concept.resort.rawValue
        case Concept.amusementPark.rawValue.localized: return Concept.amusementPark.rawValue
        case Concept.apparelShop.rawValue.localized: return Concept.apparelShop.rawValue
        case Concept.arcade.rawValue.localized: return Concept.arcade.rawValue
        case Concept.bathroom.rawValue.localized: return Concept.bathroom.rawValue
        case Concept.café.rawValue.localized: return Concept.café.rawValue
        case Concept.childSRoom.rawValue.localized: return Concept.childSRoom.rawValue
        case Concept.concert.rawValue.localized: return Concept.concert.rawValue
        case Concept.constructionSite.rawValue.localized: return Concept.constructionSite.rawValue
        case Concept.den.rawValue.localized: return Concept.den.rawValue
        case Concept.facility.rawValue.localized: return Concept.facility.rawValue
        case Concept.fancy.rawValue.localized: return Concept.fancy.rawValue
        case Concept.fantasy.rawValue.localized: return Concept.fantasy.rawValue
        case Concept.fitness.rawValue.localized: return Concept.fitness.rawValue
        case Concept.freezingCold.rawValue.localized: return Concept.freezingCold.rawValue
        case Concept.garden.rawValue.localized: return Concept.garden.rawValue
        case Concept.heritage.rawValue.localized: return Concept.heritage.rawValue
        case Concept.hospital.rawValue.localized: return Concept.hospital.rawValue
        case Concept.kitchen.rawValue.localized: return Concept.kitchen.rawValue
        case Concept.lab.rawValue.localized: return Concept.lab.rawValue
        case Concept.livingRoom.rawValue.localized: return Concept.livingRoom.rawValue
        case Concept.local.rawValue.localized: return Concept.local.rawValue
        case Concept.music.rawValue.localized: return Concept.music.rawValue
        case Concept.nature.rawValue.localized: return Concept.nature.rawValue
        case Concept.ocean.rawValue.localized: return Concept.ocean.rawValue
        case Concept.office.rawValue.localized: return Concept.office.rawValue
        case Concept.outdoors.rawValue.localized: return Concept.outdoors.rawValue
        case Concept.park.rawValue.localized: return Concept.park.rawValue
        case Concept.party.rawValue.localized: return Concept.party.rawValue
        case Concept.publicBath.rawValue.localized: return Concept.publicBath.rawValue
        case Concept.restaurant.rawValue.localized: return Concept.restaurant.rawValue
        case Concept.retro.rawValue.localized: return Concept.retro.rawValue
        case Concept.school.rawValue.localized: return Concept.school.rawValue
        case Concept.sciFi.rawValue.localized: return Concept.sciFi.rawValue
        case Concept.shop.rawValue.localized: return Concept.shop.rawValue
        case Concept.space.rawValue.localized: return Concept.space.rawValue
        case Concept.sports.rawValue.localized: return Concept.sports.rawValue
        case Concept.stylish.rawValue.localized: return Concept.stylish.rawValue
        case Concept.supermarket.rawValue.localized: return Concept.supermarket.rawValue
        case Concept.workshop.rawValue.localized: return Concept.workshop.rawValue
        default: return nil
        }
    }
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
            concepts: self.concepts
        )
    }
}

extension Item {
    
    init(
        name: String,
        category: Category,
        image: String,
        highResTexture: String?,
        genuine: Bool,
        artCategory: ArtCategory,
        buy: Int,
        sell: Int,
        size: Size,
        source: String,
        tag: String,
        translations: Translations,
        colors: [Color],
        concepts: [Concept]
    ) {
        self.name = name
        self.category = category
        self.image = image
        self.highResTexture = highResTexture
        self.genuine = genuine
        self.artCategory = artCategory
        self.buy = buy
        self.sell = sell
        self.size = size
        self.source = source
        self.tag = tag
        self.translations = translations
        self.colors = colors
        self.concepts = concepts
    }
}
