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
        let colorStrings = colors
            .map { $0.rawValue.lowercased().localized.capitalized }
        let styleStrings = Set(styles.map { $0.rawValue })
            .map { $0.lowercased().localized.capitalized }
        
        return (colorStrings + styleStrings).joined(separator: ", ")
    }
}
