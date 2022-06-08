//
//  VillagersResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - VillagersResponseDTO
struct VillagersResponseDTO: Codable, APIResponse {
    let name: String
    let iconImage: String
    let photoImage: String
    let houseImage: String?
    let species: String
    let gender: Gender
    let personality: Personality
    let subtype: Subtype
    let hobby: Hobby
    let birthday: String
    let catchphrase: String
    let favoriteSong: String
    let favoriteSaying: String
    let defaultClothing: String
    let defaultUmbrella: String
    let wallpaper: String
    let flooring: String
    let furnitureList: [Int]
    let furnitureNameList: [String]
    let diyWorkbench: String
    let kitchenEquipment: KitchenEquipment
    let nameColor: String
    let bubbleColor: String
    let filename: String
    let uniqueEntryId: String
    let catchphrases: Translations
    let translations: Translations
    let styles: [Style]
    let colors: [Color]
    let defaultClothingInternalId: Int
}

enum KitchenEquipment: Codable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let element = try? container.decode(Int.self) {
            self = .integer(element)
            return
        }
        if let element = try? container.decode(String.self) {
            self = .string(element)
            return
        }
        throw DecodingError.typeMismatch(
            KitchenEquipment.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Wrong type for KitchenEquipment")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let element):
            try container.encode(element)
        case .string(let element):
            try container.encode(element)
        }
    }
}

enum Color: String, Codable {
    case aqua = "Aqua"
    case beige = "Beige"
    case black = "Black"
    case blue = "Blue"
    case brown = "Brown"
    case colorful = "Colorful"
    case gray = "Gray"
    case green = "Green"
    case orange = "Orange"
    case pink = "Pink"
    case purple = "Purple"
    case red = "Red"
    case white = "White"
    case yellow = "Yellow"
}

enum Gender: String, Codable {
    case female = "Female"
    case male = "Male"
}

enum Hobby: String, Codable {
    case education = "Education"
    case fashion = "Fashion"
    case fitness = "Fitness"
    case music = "Music"
    case nature = "Nature"
    case play = "Play"
}

enum Personality: String, Codable {
    case bigSister = "Big Sister"
    case cranky = "Cranky"
    case jock = "Jock"
    case normal = "Normal"
    case peppy = "Peppy"
    case personalityLazy = "Lazy"
    case smug = "Smug"
    case snooty = "Snooty"
}

enum Style: String, Codable {
    case active = "Active"
    case cool = "Cool"
    case cute = "Cute"
    case elegant = "Elegant"
    case gorgeous = "Gorgeous"
    case simple = "Simple"
}

enum Subtype: String, Codable {
    case a = "A"
    case b = "B"
}

struct Translations: Codable {
    let eUde, eUen, eUit, eUnl: String
    let eUru, eUfr, eUes, uSen: String
    let uSfr, uSes, jPja, kRko: String
    let tWzh, cNzh: String
    
    enum LanguageCode: String {
        case de, en, it, nl, ru, fr, es, ja, ko, zh
    }
    
    func localizedName() -> String {
        guard let code = Locale.current.languageCode, let languageCode = LanguageCode(rawValue: code) else {
            return eUen
        }
        switch languageCode {
        case .de: return eUde
        case .en: return uSen
        case .it: return eUit
        case .nl: return eUnl
        case .ru: return eUru
        case .fr: return eUfr
        case .es: return eUes
        case .ja: return jPja
        case .ko: return kRko
        case .zh: return cNzh
        }
    }
}

extension VillagersResponseDTO {
    func toDomain() -> Villager {
        return Villager(
            name: self.name,
            iconImage: self.iconImage,
            photoImage: self.photoImage,
            houseImage: self.houseImage,
            species: self.species,
            gender: self.gender,
            personality: self.personality,
            subtype: self.subtype,
            hobby: self.hobby,
            birthday: self.birthday,
            catchphrase: self.catchphrase,
            favoriteSong: self.favoriteSong,
            furnitureList: self.furnitureList,
            furnitureNameList: self.furnitureNameList,
            diyWorkbench: self.diyWorkbench,
            kitchenEquipment: self.kitchenEquipment,
            catchphrases: self.catchphrases,
            translations: self.translations,
            styles: self.styles,
            colors: self.colors
        )
    }
}
