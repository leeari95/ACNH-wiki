//
//  Villager.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

public struct Villager {
    public let name: String
    public let iconImage: String
    public let photoImage: String
    public let houseImage: String?
    public let species: Specie
    public let gender: Gender
    public let personality: Personality
    public let subtype: Subtype
    public let hobby: Hobby
    public let birthday: String
    public let catchphrase: String
    public let favoriteSong: String
    public let furnitureList: [Int]
    public let furnitureNameList: [String]
    public let diyWorkbench: String
    public let kitchenEquipment: String
    public let catchphrases: Translations
    public let translations: Translations
    public let styles: [Style]
    public let colors: [Color]
}

public extension Villager {
    public var like: String {
        public let color = colors
            .reduce("") { $0 + $1.rawValue.lowercased().localized.capitalized + ", " }
        public let style = Set(styles.map { $0.rawValue })
            .reduce("") { $0 + $1.lowercased().localized.capitalized + ", " }
            .trimmingCharacters(in: [",", " "])
        return color + style
    }
}
