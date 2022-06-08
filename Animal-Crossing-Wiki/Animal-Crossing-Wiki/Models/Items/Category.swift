//
//  Category.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

enum Category: CaseIterable {
    case bugs
    case fish
    case seaCreatures
    case fossils
    case art
    
    var iconName: String {
        switch self {
        case .bugs:
            return "Ins13"
        case .fish:
            return "Fish6"
        case .seaCreatures:
            return "div25"
        case .fossils:
            return "icon-fossil"
        case .art:
            return "icon-board"
        }
    }
}
