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
    let species: String
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
    let kitchenEquipment: KitchenEquipment
    let catchphrases: Translations
    let translations: Translations
    let styles: [Style]
    let colors: [Color]
}
