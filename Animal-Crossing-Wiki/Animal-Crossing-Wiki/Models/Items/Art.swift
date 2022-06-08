//
//  Art.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct Art: Item {
    let name: String
    let category: Category = .art
    let image: String
    let highResTexture: String?
    let genuine: Bool
    let artCategory: ArtCategory
    let buy: Int
    let sell: Int
    let size: Size
    let tag: Tag
    let unlocked: Bool
    let isFake: Bool
    let translations: Translations
    let colors: [Color]
    let concepts: [Concept]
}
