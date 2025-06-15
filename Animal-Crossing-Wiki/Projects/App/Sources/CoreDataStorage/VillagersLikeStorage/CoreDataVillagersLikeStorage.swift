//
//  CoreDataVillagersLikeStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

final class CoreDataVillagersLikeStorage: VillagersLikeStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetch() -> [Villager] {
        let context = coreDataStorage.persistentContainer.viewContext
        var villagers: [VillagersLikeEntity] = []
        context.performAndWait {
            let object = try? self.coreDataStorage.getUserCollection(context)
            villagers = object?.villagersLike?.allObjects as? [VillagersLikeEntity] ?? []
        }
        return villagers.map { $0.toDomain() }
            .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
    }

    func update(_ villager: Villager) {
        self.coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let villagers = object.villagersLike?.allObjects as? [VillagersLikeEntity] ?? []
                if let index = villagers.firstIndex(where: { $0.name == villager.name }) {
                    object.removeFromVillagersLike(villagers[index])
                } else {
                    let newVillager = VillagersLikeEntity(villager, context: context)
                    object.addToVillagersLike(newVillager)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
