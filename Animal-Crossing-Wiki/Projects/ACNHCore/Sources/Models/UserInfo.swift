//
//  UserInfo.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

public struct UserInfo {
    private(set) var name: String
    private(set) var islandName: String
    private(set) var islandFruit: Fruit
    private(set) var hemisphere: Hemisphere
    private(set) var islandReputation: Int

    mutating func updateName(_ name: String) {
        self.name = name
    }

    mutating func updateIslandName(_ name: String) {
        self.islandName = name
    }

    mutating func updateFruit(_ fruit: Fruit) {
        self.islandFruit = fruit
    }

    mutating func updateHemisphere(_ hemisphere: Hemisphere) {
        self.hemisphere = hemisphere
    }

    mutating func updateIslandReputation(_ score: Int) {
        self.islandReputation = score
    }
}

public extension UserInfo: Equatable {
    public init() {
        self.name = ""
        self.islandName = ""
        self.islandFruit = .apple
        self.hemisphere = .north
        self.islandReputation = 0
    }
}
