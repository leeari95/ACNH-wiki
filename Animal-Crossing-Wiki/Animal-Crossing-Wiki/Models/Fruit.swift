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
}
