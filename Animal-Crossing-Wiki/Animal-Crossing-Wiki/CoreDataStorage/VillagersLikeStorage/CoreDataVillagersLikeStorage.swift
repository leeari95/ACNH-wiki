//
//  CoreDataVillagersLikeStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

final class CoreDataVillagersLikeStorage: VillagersLikeStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetchVillagerLike(completion: @escaping (Result<[Villager], Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let villagers = object?.vilagersLike?.allObjects as? [VillagersLikeEntity] ?? []
                completion(.success(villagers.map { $0.toDomain() }))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func insertVillagerLike(
        _ villager: Villager,
        completion: @escaping (Result<Villager, Error>) -> Void
    ) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let newVillager = VillagersLikeEntity(villager, context: context)
                object?.addToVilagersLike(newVillager)
                context.saveContext()
                completion(.success(newVillager.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func deleteVilagerLikeDelete(
        _ item: Villager,
        completion: @escaping (Result<Villager?, Error>) -> Void
    ) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let vilagers = object?.vilagersLike?.allObjects as? [VillagersLikeEntity] ?? []
                guard let vilager = vilagers.first else {
                    completion(.failure(CoreDataStorageError.notFound))
                    return
                }
                object?.removeFromVilagersLike(vilager)
                context.saveContext()
                completion(.success(vilager.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
}
