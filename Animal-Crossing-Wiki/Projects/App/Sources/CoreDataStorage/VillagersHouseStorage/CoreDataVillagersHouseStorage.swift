//
//  CoreDataVillagersHouseStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

final class CoreDataVillagersHouseStorage: VillagersHouseStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetch() -> [Villager] {
        let context = coreDataStorage.persistentContainer.viewContext
        var villagers: [VillagersHouseEntity] = []
        context.performAndWait {
            let object = try? self.coreDataStorage.getUserCollection(context)
            villagers = object?.villagersHouse?.allObjects as? [VillagersHouseEntity] ?? []
        }
        return villagers.compactMap { $0.toDomain() }
            .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
    }

    func update(_ villager: Villager) {
        self.coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let villagers = object.villagersHouse?.allObjects as? [VillagersHouseEntity] ?? []
                if let index = villagers.firstIndex(where: { $0.name == villager.name }) {
                    object.removeFromVillagersHouse(villagers[index])
                } else {
                    let newVillager = VillagersHouseEntity(villager, context: context)
                    object.addToVillagersHouse(newVillager)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
