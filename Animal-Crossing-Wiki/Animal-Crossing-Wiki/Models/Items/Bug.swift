//
//  Bug.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct Bug: Item {
    let name: String
    let category: Category = .bugs
    let iconImage: String
    let critterpediaImage: String
    let furnitureImage: String
    let sell: Int
    let whereHow: String
    let weather: Weather
    let spawnRates: String
    let size: Size
    let translations: Translations
    let hemispheres: Hemispheres
    let colors: [Color]
    let keyword: [Keyword : [String]]
}
