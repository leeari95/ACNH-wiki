//
//  CoreDataUserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

final class CoreDataUserInfoStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetchUserInfo(completion: @escaping (Result<UserInfo, Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let userInfo = UserInfo(
                    name: object?.name ?? "",
                    islandName: object?.islandName ?? "",
                    islandFruit: Fruit(rawValue: object?.islandFruit ?? "") ?? .apple
                )
                completion(.success(userInfo))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func updateUserInfo(_ userInfo: UserInfo, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                object?.name = userInfo.name
                object?.islandName = userInfo.islandName
                object?.islandFruit = userInfo.islandFruit.rawValue
                context.saveContext()
                completion(.success(userInfo))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func resetUserInfo() {
        coreDataStorage.performBackgroundTask { [weak self] context in
            let object = try? self?.coreDataStorage.getUserCollection(context)
            object?.name = nil
            object?.islandName = nil
            object?.islandFruit = nil
            context.saveContext()
        }
    }
}
