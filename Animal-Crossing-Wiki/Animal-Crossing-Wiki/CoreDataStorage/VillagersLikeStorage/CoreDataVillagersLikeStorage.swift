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
    
    func fetch() -> Single<[Villager]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let villagers = object.villagersLike?.allObjects as? [VillagersLikeEntity] ?? []
                    single(.success(villagers.map { $0.toDomain() }))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
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
