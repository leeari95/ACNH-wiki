//
//  UserCollectionEntity+CoreDataProperties.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//
//

import Foundation
import CoreData


extension UserCollectionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCollectionEntity> {
        return NSFetchRequest<UserCollectionEntity>(entityName: "UserCollectionEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var islandName: String?
    @NSManaged public var islandFruit: String?
    @NSManaged public var favoriteVillagers: [String]?
    @NSManaged public var islandVillagers: [String]?
    @NSManaged public var dailyTasks: [String: Bool]?
    @NSManaged public var critters: [String: String]?

    var villagersLike: [Villager] {
        var villagers = [Villager]()
        favoriteVillagers?.forEach({ name in
            if let index = Items.shared.villagers.firstIndex(where: { $0.name == name } ) {
                villagers.append(Items.shared.villagers[index])
            }
        })
        return villagers
    }
    
    var villagersHouse: [Villager] {
        var villagers = [Villager]()
        favoriteVillagers?.forEach({ name in
            if let index = Items.shared.villagers.firstIndex(where: { $0.name == name } ) {
                villagers.append(Items.shared.villagers[index])
            }
        })
        return villagers
    }
    
    var dailyCustomTasks: [DailyTask] {
        var tasks = [DailyTask]()
        dailyTasks?.forEach({ (key: String, value: Bool) in
            let task = DailyTask(icon: key, isCompleted: value)
            tasks.append(task)
        })
        return tasks
    }
    
    var allCritters: [Item] {
        var critterList = [Item]()
        critters?.forEach({ (key: String, value: String) in
            if let category = Category(rawValue: key),
               let items = Items.shared.categories[category],
               let index = items.firstIndex(where:  {$0.name == value } ) {
                critterList.append(items[index])
            }
        })
        return critterList
    }
}

extension UserCollectionEntity : Identifiable {

}
