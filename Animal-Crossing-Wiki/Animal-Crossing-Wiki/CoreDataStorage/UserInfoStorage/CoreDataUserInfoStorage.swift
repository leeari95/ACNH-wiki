//
//  CoreDataUserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

final class CoreDataUserInfoStorage: UserInfoStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetchUserInfo() -> UserInfo? {
        let context = coreDataStorage.persistentContainer.viewContext
        let object = try? self.coreDataStorage.getUserCollection(context)
        let userInfo = object?.toDomain()
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
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func resetUserInfo() {
        coreDataStorage.performBackgroundTask { [weak self] context in
            let object = try? self?.coreDataStorage.getUserCollection(context)
            object?.name = nil
            object?.islandName = nil
            object?.islandFruit = nil
            object?.hemisphere = nil
            context.saveContext()
        }
    }
}
