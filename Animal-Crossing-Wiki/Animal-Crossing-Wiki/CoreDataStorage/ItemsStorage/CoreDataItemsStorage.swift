//
//  CoreDataItemsStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

final class CoreDataItemsStorage: ItemsStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetchItem(completion: @escaping (Result<[Item], Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let itemEntities = object?.critters?.allObjects as? [ItemEntity] ?? []
                let critters = try itemEntities.map { try $0.toDomain() }
                completion(.success(critters))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func insertItem(_ item: Item, completion: @escaping (Result<Item, Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let newItem = ItemEntity(item, context: context)
                object?.addToCritters(newItem)
                context.saveContext()
                completion(.success(try newItem.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func deleteItemDelete(_ item: Item, completion: @escaping (Result<Item, Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let items = object?.critters?.allObjects as? [ItemEntity]
                guard let item = items?.filter({ $0.name == item.name }).first else {
                    completion(.failure(CoreDataStorageError.notFound))
                    return
                }
                object?.removeFromCritters(item)
                context.saveContext()
                completion(.success(try item.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
}
