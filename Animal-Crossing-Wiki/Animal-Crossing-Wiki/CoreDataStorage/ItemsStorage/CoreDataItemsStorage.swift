//
//  CoreDataItemsStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

final class CoreDataItemsStorage: ItemsStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetch() -> Single<[Item]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let itemEntities = object.critters?.allObjects as? [ItemEntity] ?? []
                    let critters = try itemEntities.map { try $0.toDomain() }
                    single(.success(critters))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }
    
    func update(_ item: Item) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                if let index = items.firstIndex(where: { $0.name == item.name && $0.isFake == item.isFake }) {
                    object.removeFromCritters(items[index])
                } else {
                    let newItem = ItemEntity(item, context: context)
                    object.addToCritters(newItem)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
