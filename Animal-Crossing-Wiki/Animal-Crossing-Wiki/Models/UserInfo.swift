//
//  UserInfo.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

struct UserInfo {
    private(set) var name: String
    private(set) var islandName: String
    private(set) var islandFruit: Fruit
    private(set) var hemisphere: Hemisphere
    
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
}
