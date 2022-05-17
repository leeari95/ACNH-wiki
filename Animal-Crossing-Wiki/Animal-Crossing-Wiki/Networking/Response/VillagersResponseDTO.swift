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

// MARK: - Translations
struct Translations: Codable {
    let eUde: String
    let eUen: String
    let eUit: String
    let eUnl: String
    let eUru: String
    let eUfr: String
    let eUes: String
    let uSen: String
    let uSfr: String
    let uSes: String
    let jPja: String
    let kRko: String
    let tWzh: String
    let cNzh: String
}

enum Color: Codable {
    case aqua
    case beige
    case black
    case blue
    case brown
    case colorful
    case gray
    case green
    case orange
    case pink
    case purple
    case red
    case white
    case yellow
}

enum Gender: Codable {
    case female
    case male
}

enum Hobby: Codable {
    case education
    case fashion
    case fitness
    case music
    case nature
    case play
}

enum KitchenEquipment: Codable {
    case integer(Int)
    case string(String)
}

enum Personality: Codable {
    case bigSister
    case cranky
    case jock
    case normal
    case peppy
    case personalityLazy
    case smug
    case snooty
}

enum Style: Codable {
    case active
    case cool
    case cute
    case elegant
    case gorgeous
    case simple
}

enum Subtype:Codable {
    case a
    case b
}
