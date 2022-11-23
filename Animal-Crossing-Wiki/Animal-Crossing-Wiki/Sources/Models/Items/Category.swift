//
//  Category.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

enum Category: String, CaseIterable {
    case fishes = "Fishes"
    case seaCreatures = "Sea Creatures"
    case bugs = "Bugs"
    case fossils = "Fossils"
    case art = "Art"
    case housewares = "Housewares"
    case miscellaneous = "Miscellaneous"
    case wallMounted = "Wall mounted"
    case wallpaper = "Wallpaper"
    case floors = "Floors"
    case rugs = "Rugs"
    case other = "Other"
    case ceilingDecor = "Ceiling Decor"
    case recipes = "Recipes"
    case songs = "Songs"
    case photos = "Photos"
    case tops = "Tops"
    case bottoms = "Bottoms"
    case dressUp = "Dress-Up"
    case headwear = "Headwear"
    case accessories = "Accessories"
    case socks = "Socks"
    case shoes = "Shoes"
    case bags = "Bags"
    case umbrellas = "Umbrellas"
    case wetSuit = "Wet Suit"
    
    var iconName: String {
        switch self {
        case .bugs: return "Ins13"
        case .fishes: return "Fish6"
        case .seaCreatures: return "div25"
        case .fossils: return "icon-fossil"
        case .art: return "icon-board"
        case .housewares: return "icon-housewares"
        case .miscellaneous: return "icon-miscellaneous"
        case .wallMounted: return "icon-wallmounted"
        case .wallpaper: return "icon-wallpaper"
        case .floors: return "icon-floor"
        case .rugs: return "icon-rug"
        case .other: return "icon-leaf"
        case .ceilingDecor: return "icon-ceiling"
        case .recipes: return "icon-recipe"
        case .songs: return "icon-song"
        case .photos: return "icon-photos"
        case .tops: return "icon-top"
        case .bottoms: return "icon-pant"
        case .dressUp: return "icon-top"
        case .headwear: return "icon-helm"
        case .accessories: return "icon-glasses"
        case .socks: return "icon-socks"
        case .shoes: return "icon-shoes"
        case .bags: return "icon-bag"
        case .umbrellas: return "icon-umbrella"
        case .wetSuit: return "icon-wetsuit"
        }
    }

    var progressIconName: String {
        switch self {
        case .bugs: return "Ins1"
        case .fishes: return "Fish6"
        case .seaCreatures: return "div11"
        case .fossils: return "icon-fossil"
        case .art: return "icon-board"
        case .housewares: return "icon-housewares"
        case .miscellaneous: return "icon-miscellaneous"
        case .wallMounted: return "icon-wallmounted"
        case .wallpaper: return "icon-wallpaper"
        case .floors: return "icon-floor"
        case .rugs: return "icon-rug"
        case .other: return "icon-leaf"
        case .ceilingDecor: return "icon-ceiling"
        case .recipes: return "icon-recipe"
        case .songs: return "icon-song"
        case .photos: return "icon-photos"
        case .tops: return "icon-top"
        case .bottoms: return "icon-pant"
        case .dressUp: return "icon-top"
        case .headwear: return "icon-helm"
        case .accessories: return "icon-glasses"
        case .socks: return "icon-socks"
        case .shoes: return "icon-shoes"
        case .bags: return "icon-bag"
        case .umbrellas: return "icon-umbrella"
        case .wetSuit: return "icon-wetsuit"
        }
    }
    
    static func items() -> [Category] {
        [
            .fishes, .seaCreatures, .bugs,
            .fossils, .art, .housewares,
            .miscellaneous, .wallMounted, .ceilingDecor,
            .wallpaper, .floors, .rugs,
            .other, .recipes, .songs, .photos,
            .tops, .bottoms, .dressUp, .headwear, .accessories, .socks, .shoes, .bags, .umbrellas, .wetSuit
        ]
    }
    
    static func progress() -> [Category] {
        [.fishes, .bugs, .seaCreatures, .fossils, .art]
    }
    
    static var critters: [Category] {
        [.fishes, .seaCreatures, .bugs]
    }
    
    static func furniture() -> [Category] {
        [
            .housewares, .miscellaneous, .wallMounted,
            .ceilingDecor, .wallpaper, .floors,
            .rugs, .other, .songs, .photos,
            .tops, .bottoms, .dressUp, .headwear, .accessories, .socks, .shoes, .bags, .umbrellas, .wetSuit
        ]
    }
}

extension Category: Comparable {
    
    private var sortOrder: Int {
        switch self {
        case .fishes: return 0
        case .seaCreatures: return 1
        case .bugs: return 2
        case .fossils: return 3
        case .art: return 4
        case .housewares: return 5
        case .miscellaneous: return 6
        case .wallMounted: return 7
        case .wallpaper: return 8
        case .floors: return 9
        case .rugs: return 10
        case .other: return 11
        case .ceilingDecor: return 12
        case .recipes: return 13
        case .songs: return 14
        case .photos: return 15
        case .tops: return 16
        case .bottoms: return 17
        case .dressUp: return 18
        case .headwear: return 19
        case .accessories: return 20
        case .socks: return 21
        case .shoes: return 22
        case .bags: return 23
        case .umbrellas: return 24
        case .wetSuit: return 25
        }
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.sortOrder == rhs.sortOrder
    }
    
    static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
    
}
