//
//  CoreDataVillagersHouseStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

final class CoreDataVillagersHouseStorage: VillagersHouseStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetchVillagerHouse(completion: @escaping (Result<[Villager], Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let villagers = object?.vilagersHouse?.allObjects as? [VillagersHouseEntity] ?? []
                completion(.success(villagers.map { $0.toDomain() }))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func insertVillagerHouse(
        _ villager: Villager,
        completion: @escaping (Result<Villager, Error>) -> Void
    ) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let newVillager = VillagersHouseEntity(villager, context: context)
                object?.addToVilagersHouse(newVillager)
                context.saveContext()
                completion(.success(newVillager.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func deleteVilagerHouseelete(
        _ item: Villager,
        completion: @escaping (Result<Villager?, Error>) -> Void
    ) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let vilagers = object?.vilagersHouse?.allObjects as? [VillagersHouseEntity] ?? []
                guard let vilager = vilagers.first else {
                    completion(.failure(CoreDataStorageError.notFound))
                    return
                }
                object?.removeFromVilagersHouse(vilager)
                context.saveContext()
                completion(.success(vilager.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
}
