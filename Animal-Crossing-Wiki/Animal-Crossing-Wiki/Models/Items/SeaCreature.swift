//
//  SeaCreature.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct SeaCreature: Item {
    let name: String
    let category: Category = .seaCreatures
    let iconImage: String
    let critterpediaImage: String
    let furnitureImage: String
    let sell: Int
    let shadow: Shadow
    let movementSpeed: MovementSpeed
    let spawnRates: String
    let size: Size
    let translations: Translations
    let hemispheres: Hemispheres
    let colors: [Color]?
}
