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
        }
    }
    
    static func items() -> [Category] {
        [
            .fishes, .seaCreatures, .bugs, .fossils, .art,
            .housewares, .miscellaneous, .wallMounted, .ceilingDecor, .wallpaper, .floors, .rugs, .other
        ]
    }
    
    static func progress() -> [Category] {
        [.fishes, .bugs, .seaCreatures, .fossils, .art]
    }
    
    static var critters: [Category] {
        [.fishes, .seaCreatures, .bugs]
    }
    
    static func housewares() -> [Category] {
        [.housewares, .miscellaneous, .wallMounted, .ceilingDecor, .wallpaper, .floors, .rugs, .other]
    }
}
