//
//  CoreDataUserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift
import CoreData

final class CoreDataUserInfoStorage: UserInfoStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetchUserInfo() -> UserInfo? {
        let context = coreDataStorage.persistentContainer.viewContext
        var userInfo: UserInfo?
        context.performAndWait {
            let object = try? self.coreDataStorage.getUserCollection(context)
            userInfo = object?.toDomain()
        }
        return userInfo
    }

    func updateUserInfo(_ userInfo: UserInfo) {
        self.coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                object.name = userInfo.name
                object.islandName = userInfo.islandName
                object.islandFruit = userInfo.islandFruit.rawValue
                object.hemisphere = userInfo.hemisphere.rawValue
                object.islandReputation = Int16(userInfo.islandReputation)
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }

    func resetUserInfo() {
        coreDataStorage.performBackgroundTask { [weak self] context in
            let object = try? self?.coreDataStorage.getUserCollection(context) as? NSManagedObject
            object.flatMap { context.delete($0) }
            context.saveContext()
        }
    }
}
