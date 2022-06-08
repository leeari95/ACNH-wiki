//
//  Item.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

protocol Item {
    var name: String { get }
    var category: Category { get }
    var colors: [Color] { get }
    var styles: [Style] { get }
    var concepts: [Concept] { get }
}

extension Item {
    var colors: [Color] { return [] }
    var styles: [Style] { return [] }
    var concepts: [Concept] { return [] }
}
