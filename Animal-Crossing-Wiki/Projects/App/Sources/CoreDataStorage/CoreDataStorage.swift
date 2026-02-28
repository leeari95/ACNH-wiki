//
//  CoreDataStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/09.
//

import Foundation
import CoreData
import CloudKit
import OSLog

enum CoreDataStorageError: LocalizedError {
    case readError(Error)
    case notFound
    case categoryNotFound

    var errorDescription: String? {
        switch self {
        case .readError(let error):
            return "⛔️ 데이터 불러오기 실패\n에러내용: \(error.localizedDescription)"
        case .notFound:
            return "⛔️ 데이터를 찾지 못했습니다."
        case .categoryNotFound:
            return "⛔️ 카테고리가 존재하지 않는 아이템입니다."
        }
    }
}

final class CoreDataStorage {

    static let shared = CoreDataStorage()

    static let didReceiveRemoteChanges = Notification.Name("CoreDataStorageDidReceiveRemoteChanges")
    static let didStartCloudImport = Notification.Name("CoreDataStorageDidStartCloudImport")
    static let didFinishCloudImport = Notification.Name("CoreDataStorageDidFinishCloudImport")
    static let cloudSyncDidFail = Notification.Name("CoreDataStorageCloudSyncDidFail")
    static let iCloudAccountDidChange = Notification.Name("CoreDataStorageICloudAccountDidChange")

    private init() {}

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage")

        container.persistentStoreDescriptions.forEach { description in
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.leeari.NookPortalPlus"
            )

            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                os_log(.error, log: .default, "CoreData store load failed: %{public}@", error.localizedDescription)
            }
        })

        observeRemoteChanges(for: container.persistentStoreCoordinator)
        observeCloudKitEvents()
        observeAccountChanges()

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        migrateExistingDataToCloudKit(container: container)

        return container
    }()

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - iCloud Account Status

    func checkiCloudAccountStatus(completion: ((CKAccountStatus) -> Void)? = nil) {
        CKContainer(identifier: "iCloud.leeari.NookPortalPlus").accountStatus { status, error in
            if let error {
                os_log(.error, log: .default, "iCloud account status check failed: %{public}@", error.localizedDescription)
            }
            DispatchQueue.main.async {
                completion?(status)
            }
        }
    }

    // MARK: - Persistent History Cleanup

    func cleanupPersistentHistory() {
        persistentContainer.performBackgroundTask { context in
            guard let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
                return
            }
            let request = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)
            do {
                try context.execute(request)
            } catch {
                os_log(.error, log: .default, "Persistent history cleanup failed: %{public}@", error.localizedDescription)
            }
        }
    }

    // MARK: - Remote Changes

    private func observeRemoteChanges(for coordinator: NSPersistentStoreCoordinator) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: coordinator
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        NotificationCenter.default.post(name: Self.didReceiveRemoteChanges, object: nil)
    }

    // MARK: - CloudKit Events

    private func observeCloudKitEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }

    @objc private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }

        let type: String
        switch event.type {
        case .setup: type = "Setup"
        case .import: type = "Import"
        case .export: type = "Export"
        @unknown default: type = "Unknown"
        }

        if event.endDate != nil {
            if let error = event.error {
                os_log(.error, log: .default, "CloudKit %{public}@ failed: %{public}@", type, error.localizedDescription)
                postSyncFailureIfNeeded(error)
            } else {
                os_log(.info, log: .default, "CloudKit %{public}@ succeeded", type)
            }
            if event.type == .import {
                NotificationCenter.default.post(name: Self.didFinishCloudImport, object: nil)
            }
        } else {
            os_log(.info, log: .default, "CloudKit %{public}@ started", type)
            if event.type == .import {
                NotificationCenter.default.post(name: Self.didStartCloudImport, object: nil)
            }
        }
    }

    private func postSyncFailureIfNeeded(_ error: Error) {
        let nsError = error as NSError
        var reason = "unknown"

        if let ckError = error as? CKError {
            switch ckError.code {
            case .quotaExceeded:
                reason = "quota_exceeded"
            case .notAuthenticated:
                reason = "not_authenticated"
            case .networkFailure, .networkUnavailable:
                reason = "network"
            default:
                reason = ckError.code.rawValue.description
            }
        } else if nsError.domain == CKError.errorDomain {
            if nsError.code == CKError.quotaExceeded.rawValue {
                reason = "quota_exceeded"
            } else if nsError.code == CKError.notAuthenticated.rawValue {
                reason = "not_authenticated"
            }
        }

        NotificationCenter.default.post(
            name: Self.cloudSyncDidFail,
            object: nil,
            userInfo: ["reason": reason]
        )
    }

    // MARK: - Account Change Observation

    private func observeAccountChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountChange),
            name: .CKAccountChanged,
            object: nil
        )
    }

    @objc private func handleAccountChange() {
        os_log(.info, log: .default, "iCloud account changed")
        checkiCloudAccountStatus { status in
            NotificationCenter.default.post(
                name: Self.iCloudAccountDidChange,
                object: nil,
                userInfo: ["status": status.rawValue]
            )
        }
    }
}

// MARK: - Migration

extension CoreDataStorage {

    /// 기존 로컬 데이터를 CloudKit에 export하기 위해 모든 레코드를 한 번 터치하는 일회성 마이그레이션
    private func migrateExistingDataToCloudKit(container: NSPersistentCloudKitContainer) {
        let key = "didMigrateExistingDataToCloudKit_v2"
        guard !UserDefaults.standard.bool(forKey: key) else {
            return
        }

        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let entityNames = [
                "UserCollectionEntity",
                "ItemEntity",
                "DailyTaskEntity",
                "VillagersLikeEntity",
                "VillagersHouseEntity",
                "NPCLikeEntity",
                "VariantCollectionEntity"
            ]

            var totalCount = 0
            for entityName in entityNames {
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                do {
                    let objects = try context.fetch(request)
                    for object in objects {
                        if let firstAttribute = object.entity.attributesByName.first {
                            let value = object.value(forKey: firstAttribute.key)
                            object.setValue(value, forKey: firstAttribute.key)
                        }
                    }
                    totalCount += objects.count
                } catch {
                    os_log(.error, log: .default, "CloudKit migration failed: %{public}@ - %{public}@", entityName, error.localizedDescription)
                    return
                }
            }

            if totalCount > 0 {
                do {
                    try context.save()
                } catch {
                    os_log(.error, log: .default, "CloudKit migration save failed: %{public}@", error.localizedDescription)
                    return
                }
            }

            UserDefaults.standard.set(true, forKey: key)
            os_log(.info, log: .default, "CloudKit migration completed: %d records", totalCount)
        }
    }

    func getUserCollection(_ context: NSManagedObjectContext) throws -> UserCollectionEntity {
        let request = UserCollectionEntity.fetchRequest()
        let results = try context.fetch(request)

        // CloudKit 동기화로 복수의 UserCollectionEntity가 존재할 수 있음
        // relationship이 있는(데이터가 있는) 엔티티를 우선 반환
        let sorted = results.sorted { lhs, rhs in
            let lhsCount = (lhs.critters?.count ?? 0)
                + (lhs.villagersLike?.count ?? 0)
                + (lhs.villagersHouse?.count ?? 0)
                + (lhs.dailyTasks?.count ?? 0)
            let rhsCount = (rhs.critters?.count ?? 0)
                + (rhs.villagersLike?.count ?? 0)
                + (rhs.villagersHouse?.count ?? 0)
                + (rhs.dailyTasks?.count ?? 0)
            return lhsCount > rhsCount
        }

        return sorted.first ?? UserCollectionEntity(UserInfo(), context: context)
    }
}

extension NSManagedObjectContext {
    func saveContext() {
        if self.hasChanges {
            do {
                try save()
            } catch {
                os_log(.error, log: .default, "CoreData save failed: %{public}@", error.localizedDescription)
            }
        }
    }
}
