//
//  Hemisphere.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/13.
//

import Foundation

enum Hemisphere: String, CaseIterable {
    case north = "North"
    case south = "Sorth"
}

extension Hemisphere: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.north, .north),
            (.south, .south):
            return true
        default:
            return false
        }
    }
}
