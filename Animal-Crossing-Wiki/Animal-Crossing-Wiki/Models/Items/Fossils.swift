//
//  Fossils.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct Fossils: Item {
    let name: String
    let category: Category = .fossils
    let image: String
    let buy: Int
    let sell: Int
    let size: Size
    let source: String
    let museum: Museum
    let translations: Translations
    let colors: [Color]
    var keyword: [Keyword : [String]]
}
