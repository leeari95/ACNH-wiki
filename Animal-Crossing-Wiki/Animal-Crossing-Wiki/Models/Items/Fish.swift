//
//  Fish.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct Fish: Item {
    let name: String
    let category: Category = .fish
    let iconImage: String
    let critterpediaImage: String
    let furnitureImage: String
    let sell: Int
    let whereHow: WhereHow
    let shadow: Shadow
    let catchDifficulty: CatchDifficulty
    let vision: Vision
    let translations: Translations
    let hemispheres: Hemispheres
    let colors: [Color]
    let keyword: [Keyword : [String]]
}
