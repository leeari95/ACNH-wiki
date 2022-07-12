//
//  Fruit.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

enum Fruit: String, CaseIterable {
    case apple
    case orange
    case pear
    case cherry
    case peach
    
    var imageName: String {
        return self.rawValue.capitalized
    }
    
    static func title(_ string: String) -> String? {
        switch string {
        case Fruit.apple.imageName.localized: return Fruit.apple.rawValue
        case Fruit.orange.imageName.localized: return Fruit.orange.rawValue
        case Fruit.pear.imageName.localized: return Fruit.pear.rawValue
        case Fruit.cherry.imageName.localized: return Fruit.cherry.rawValue
        case Fruit.peach.imageName.localized: return Fruit.peach.rawValue
        default: return nil
        }
    }
}

extension Fruit: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.apple, .apple),
            (.orange, .orange),
            (.pear, .pear),
            (.cherry, .cherry),
            (.peach, .peach):
            return true
        default:
            return false
        }
    }
}
