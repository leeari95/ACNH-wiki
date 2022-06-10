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
    var sell: Int { get }
    var translations: Translations { get }
    var colors: [Color] { get }
    var keyword: [Keyword: [String]] { get }
    
    var image: String { get }
    var iconImage: String { get }
    var critterpediaImage: String { get }
    var furnitureImage: String { get }
    var hemispheres: Hemispheres { get }
    var whereHow: WhereHow { get }
    var weather: Weather { get }
    var spawnRates: String { get }
    var catchDifficulty: CatchDifficulty { get }
    var vision: Vision { get }
    var shadow: Shadow { get }
    var movementSpeed: MovementSpeed { get }
    var buy: Int { get }
    var museum: Museum { get }
    var highResTexture: String { get }
    var genuine: Bool { get }
    var artCategory: ArtCategory { get }
    var unlocked: Bool { get }
    var isFake: Bool { get }
    var size: Size { get }
}

extension Item {
    var image: String {
        return ""
    }
    var iconImage: String {
        return ""
    }
    var critterpediaImage: String {
        return ""
    }
    var furnitureImage: String {
        return ""
    }
    var hemispheres: Hemispheres {
        return Hemispheres(
            north: .init(
                time: [],
                months: [],
                monthsArray: []
            ),
            south: .init(
                time: [],
                months: [],
                monthsArray: []
            )
        )
    }
    var whereHow: WhereHow {
        return .pier
    }
    var weather: Weather {
        return .anyExceptRain
    }
    var spawnRates: String {
        return ""
    }
    var catchDifficulty: CatchDifficulty {
        return .easy
    }
    var vision: Vision {
        return .medium
    }
    var shadow: Shadow {
        return .medium
    }
    var movementSpeed: MovementSpeed {
        return .medium
    }
    var buy: Int {
        return 0
    }
    var museum: Museum {
        return .room1
    }
    var highResTexture: String {
        return ""
    }
    var genuine: Bool {
        return false
    }
    var artCategory: ArtCategory {
        return .housewares
    }
    var unlocked: Bool {
        return false
    }
    var isFake: Bool {
        return false
    }
    var size: Size {
        return .the1X1
    }
}
}
