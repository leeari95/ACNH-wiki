//
//  UserCollectionEntity+Mapping.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/23.
//

import Foundation
import CoreData

extension UserCollectionEntity {
    convenience init(_ userInfo: UserInfo, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = userInfo.name
        self.islandName = userInfo.islandName
        self.islandFruit = userInfo.islandFruit.imageName
        self.hemisphere = userInfo.hemisphere.rawValue.capitalized
        self.islandReputation = Int16(userInfo.islandReputation)
    }
    
    func toDomain() -> UserInfo {
        return UserInfo(
            name: self.name ?? "",
            islandName: self.islandName ?? "",
            islandFruit: Fruit(rawValue: self.islandFruit ?? "") ?? .apple,
            hemisphere: Hemisphere(rawValue: self.hemisphere ?? "") ?? .north,
            islandReputation: Int(self.islandReputation)
        )
    }
}
