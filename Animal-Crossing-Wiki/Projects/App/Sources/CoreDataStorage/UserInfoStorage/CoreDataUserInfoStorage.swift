//
//  CoreDataUserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift
import CoreData
import os

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
                os_log(.error, log: .default, "UserInfoStorage error: %{public}@", error.localizedDescription)
            }
        }
    }

    func resetUserInfo() {
        coreDataStorage.performBackgroundTask { [weak self] context in
            guard let self else { return }
            let object = try? self.coreDataStorage.getUserCollection(context) as? NSManagedObject
            object.flatMap { context.delete($0) }
            context.saveContext()
            // 의도적 초기화이므로 기존 유저 플래그를 리셋하여 새 UC 생성을 허용
            self.coreDataStorage.clearHasEverHadUserCollection()
            // sync reset 이전 백업 보존도 해제 — 새로 쌓는 데이터가 다시 로컬 백업에 반영되도록
            SafetySnapshotService.shared.releaseResetHold()
        }
    }
}
