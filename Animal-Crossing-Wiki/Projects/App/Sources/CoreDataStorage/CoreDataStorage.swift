//
//  CoreDataStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/09.
//

import Foundation
import CoreData

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

    private init() {}

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage")

        container.persistentStoreDescriptions.forEach { description in
            // Automatic lightweight migration 설정 (새 entity 추가 시 자동 마이그레이션)
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.leeari.NookPortalPlus"
            )

            // Persistent History Tracking (CloudKit 동기화 필수)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        // lazy var 초기화 완료 후 등록해야 재진입 방지
        observeRemoteChanges(for: container.persistentStoreCoordinator)
        observeCloudKitEvents()

        // Background context와 viewContext 자동 병합 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        migrateExistingDataToCloudKit(container: container)

        return container
    }()

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

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
                as? NSPersistentCloudKitContainer.Event else { return }

        let type: String
        switch event.type {
        case .setup: type = "Setup"
        case .import: type = "Import"
        case .export: type = "Export"
        @unknown default: type = "Unknown"
        }

        if event.endDate != nil {
            if let error = event.error {
                debugPrint("☁️ CloudKit \(type) failed: \(error.localizedDescription)")
            } else {
                debugPrint("☁️ CloudKit \(type) succeeded")
            }
        } else {
            debugPrint("☁️ CloudKit \(type) started")
        }
    }
}

extension CoreDataStorage {

    /// 기존 로컬 데이터를 CloudKit에 export하기 위해 모든 레코드를 한 번 터치하는 일회성 마이그레이션
    private func migrateExistingDataToCloudKit(container: NSPersistentCloudKitContainer) {
        let key = "didMigrateExistingDataToCloudKit_v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

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
                        // 실제 속성 값을 다시 설정하여 CloudKit export 트리거
                        if let firstAttribute = object.entity.attributesByName.first {
                            let value = object.value(forKey: firstAttribute.key)
                            object.setValue(value, forKey: firstAttribute.key)
                        }
                    }
                    totalCount += objects.count
                } catch {
                    debugPrint("☁️ Migration failed: \(entityName) - \(error.localizedDescription)")
                }
            }

            if totalCount > 0 {
                context.saveContext()
            }

            UserDefaults.standard.set(true, forKey: key)
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
                let nsError = error as NSError
                debugPrint("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
