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
    
    var iconName: String {
        switch self {
        case .bugs:
            return "Ins13"
        case .fishes:
            return "Fish6"
        case .seaCreatures:
            return "div25"
        case .fossils:
            return "icon-fossil"
        case .art:
            return "icon-board"
        }
    }
    
    static func items() -> [Category] {
        [.fishes, .seaCreatures, .bugs, .fossils, .art]
    }
    
    static var critters: [Category] {
        [.fishes, .seaCreatures, .bugs]
    }
}
