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
    let species: Specie
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

enum Specie: String, Codable, CaseIterable {
    case hamster = "Hamster"
    case dog = "Dog"
    case cow = "Cow"
    case squirrel = "Squirrel"
    case koala = "Koala"
    case rhinoceros = "Rhinoceros"
    case rabbit = "Rabbit"
    case hippo = "Hippo"
    case eagle = "Eagle"
    case bull = "Bull"
    case pig = "Pig"
    case kangaroo = "Kangaroo"
    case gorilla = "Gorilla"
    case pstrich = "Ostrich"
    case deer = "Deer"
    case monkey = "Monkey"
    case horse = "Horse"
    case bearCub = "Bear cub"
    case bear = "Bear"
    case chicken = "Chicken"
    case cat = "Cat"
    case tiger = "Tiger"
    case octopus = "Octopus"
    case alligator = "Alligator"
    case anteater = "Anteater"
    case penguin = "Penguin"
    case bird = "Bird"
    case goat = "Goat"
    case frog = "Frog"
    case sheep = "Sheep"
    case duck = "Duck"
    case mouse = "Mouse"
    case wolf = "Wolf"
    case elephant = "Elephant"
    case lion = "Lion"
    
    static func transform(localizedString: String) -> String? {
        switch localizedString {
        case Specie.hamster.rawValue.localized: return Specie.hamster.rawValue
        case Specie.dog.rawValue.localized: return Specie.dog.rawValue
        case Specie.cow.rawValue.localized: return Specie.cow.rawValue
        case Specie.squirrel.rawValue.localized: return Specie.squirrel.rawValue
        case Specie.koala.rawValue.localized: return Specie.koala.rawValue
        case Specie.rhinoceros.rawValue.localized: return Specie.rhinoceros.rawValue
        case Specie.rabbit.rawValue.localized: return Specie.rabbit.rawValue
        case Specie.hippo.rawValue.localized: return Specie.hippo.rawValue
        case Specie.eagle.rawValue.localized: return Specie.eagle.rawValue
        case Specie.bull.rawValue.localized: return Specie.bull.rawValue
        case Specie.pig.rawValue.localized: return Specie.pig.rawValue
        case Specie.kangaroo.rawValue.localized: return Specie.kangaroo.rawValue
        case Specie.gorilla.rawValue.localized: return Specie.gorilla.rawValue
        case Specie.pstrich.rawValue.localized: return Specie.pstrich.rawValue
        case Specie.deer.rawValue.localized: return Specie.deer.rawValue
        case Specie.monkey.rawValue.localized: return Specie.monkey.rawValue
        case Specie.horse.rawValue.localized: return Specie.horse.rawValue
        case Specie.bearCub.rawValue.localized: return Specie.bearCub.rawValue
        case Specie.bear.rawValue.localized: return Specie.bear.rawValue
        case Specie.chicken.rawValue.localized: return Specie.chicken.rawValue
        case Specie.cat.rawValue.localized: return Specie.cat.rawValue
        case Specie.tiger.rawValue.localized: return Specie.tiger.rawValue
        case Specie.octopus.rawValue.localized: return Specie.octopus.rawValue
        case Specie.alligator.rawValue.localized: return Specie.alligator.rawValue
        case Specie.anteater.rawValue.localized: return Specie.anteater.rawValue
        case Specie.penguin.rawValue.localized: return Specie.penguin.rawValue
        case Specie.bird.rawValue.localized: return Specie.bird.rawValue
        case Specie.goat.rawValue.localized: return Specie.goat.rawValue
        case Specie.frog.rawValue.localized: return Specie.frog.rawValue
        case Specie.sheep.rawValue.localized: return Specie.sheep.rawValue
        case Specie.duck.rawValue.localized: return Specie.duck.rawValue
        case Specie.mouse.rawValue.localized: return Specie.mouse.rawValue
        case Specie.wolf.rawValue.localized: return Specie.wolf.rawValue
        case Specie.elephant.rawValue.localized: return Specie.elephant.rawValue
        case Specie.lion.rawValue.localized: return Specie.lion.rawValue
        default: return nil
        }
    }
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

enum Color: String, Codable, CaseIterable {
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
    
    static func transform(_ localizedString: String) -> String? {
        switch localizedString {
        case Color.aqua.rawValue.localized : return Color.aqua.rawValue
        case Color.beige.rawValue.localized : return Color.beige.rawValue
        case Color.black.rawValue.localized : return Color.black.rawValue
        case Color.blue.rawValue.localized : return Color.blue.rawValue
        case Color.brown.rawValue.localized : return Color.brown.rawValue
        case Color.colorful.rawValue.localized : return Color.colorful.rawValue
        case Color.gray.rawValue.localized : return Color.gray.rawValue
        case Color.green.rawValue.localized : return Color.green.rawValue
        case Color.orange.rawValue.localized : return Color.orange.rawValue
        case Color.pink.rawValue.localized : return Color.pink.rawValue
        case Color.purple.rawValue.localized : return Color.purple.rawValue
        case Color.red.rawValue.localized : return Color.red.rawValue
        case Color.white.rawValue.localized : return Color.white.rawValue
        case Color.yellow.rawValue.localized : return Color.yellow.rawValue
        default: return nil
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case female = "Female"
    case male = "Male"
    
    static func transform(localizedString: String) -> String? {
        switch localizedString {
        case Gender.female.rawValue.localized: return Gender.female.rawValue
        case Gender.male.rawValue.localized: return Gender.male.rawValue
        default: return nil
        }
    }
}

enum Hobby: String, Codable {
    case education = "Education"
    case fashion = "Fashion"
    case fitness = "Fitness"
    case music = "Music"
    case nature = "Nature"
    case play = "Play"
}

enum Personality: String, Codable, CaseIterable {
    case bigSister = "Big Sister"
    case cranky = "Cranky"
    case jock = "Jock"
    case normal = "Normal"
    case peppy = "Peppy"
    case personalityLazy = "Lazy"
    case smug = "Smug"
    case snooty = "Snooty"
    
    static func transform(localizedString: String) -> String? {
        switch localizedString {
        case Personality.bigSister.rawValue.localized: return Personality.bigSister.rawValue
        case Personality.cranky.rawValue.localized: return Personality.cranky.rawValue
        case Personality.jock.rawValue.localized: return Personality.jock.rawValue
        case Personality.normal.rawValue.localized: return Personality.normal.rawValue
        case Personality.peppy.rawValue.localized: return Personality.peppy.rawValue
        case Personality.personalityLazy.rawValue.localized: return Personality.personalityLazy.rawValue
        case Personality.smug.rawValue.localized: return Personality.smug.rawValue
        case Personality.snooty.rawValue.localized: return Personality.snooty.rawValue
        default: return nil
        }
    }
}

enum Style: String, Codable {
    case active = "Active"
    case cool = "Cool"
    case cute = "Cute"
    case elegant = "Elegant"
    case gorgeous = "Gorgeous"
    case simple = "Simple"
}

enum Subtype: String, Codable, CaseIterable {
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
            return uSen
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
        let kitchenEquipment: String
        switch self.kitchenEquipment {
        case .integer(let number):
            kitchenEquipment = number.description
        case .string(let text):
            kitchenEquipment = text
        }
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
            kitchenEquipment: kitchenEquipment,
            catchphrases: self.catchphrases,
            translations: self.translations,
            styles: self.styles,
            colors: self.colors
        )
    }
}
