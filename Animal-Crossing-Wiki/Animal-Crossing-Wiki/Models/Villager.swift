//
//  Villager.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct Villager {
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
    let furnitureList: [Int]
    let furnitureNameList: [String]
    let diyWorkbench: String
    let kitchenEquipment: String
    let catchphrases: Translations
    let translations: Translations
    let styles: [Style]
    let colors: [Color]
}

extension Villager {
    var like: String {
        let color = colors
            .reduce("") { $0 + $1.rawValue.capitalized + ", " }
        let style = styles
            .reduce("") { $0 + $1.rawValue.capitalized + ", " }
            .trimmingCharacters(in: [",", " "])
        return color + style
    }
}
