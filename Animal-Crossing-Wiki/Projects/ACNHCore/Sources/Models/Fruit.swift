//
//  Fruit.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

public enum Fruit: String, CaseIterable {
    case apple
    case orange
    case pear
    case cherry
    case peach

    public var imageName: String {
        return self.rawValue.capitalized
    }

    static func transform(_ string: String) -> String? {
        switch string {
        case Fruit.apple.rawValue.localized: return Fruit.apple.rawValue
        case Fruit.orange.rawValue.localized: return Fruit.orange.rawValue
        case Fruit.pear.rawValue.localized: return Fruit.pear.rawValue
        case Fruit.cherry.rawValue.localized: return Fruit.cherry.rawValue
        case Fruit.peach.rawValue.localized: return Fruit.peach.rawValue
        default: return nil
        }
    }
}

public extension Fruit: Equatable {
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
