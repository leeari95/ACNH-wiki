//
//  CoreDataStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/09.
//

import Foundation
import CoreData
import CloudKit
import os
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

    private let lastDiagnosticsDate = OSAllocatedUnfairLock(initialState: Date.distantPast)

    /// Import 완료 시 Persistent History에서 실제 데이터 변경 여부를 판별하기 위한 토큰
    private let _lastHistoryToken = OSAllocatedUnfairLock<NSPersistentHistoryToken?>(initialState: nil)

    /// 신규 설치 시 CloudKit Import 완료 전까지 UC 생성을 억제하는 플래그
    private let _isWaitingForFirstImport = OSAllocatedUnfairLock(initialState: false)
    private(set) var isWaitingForFirstImport: Bool {
        get { _isWaitingForFirstImport.withLock { $0 } }
        set { _isWaitingForFirstImport.withLock { $0 = newValue } }
    }

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

        initializeHistoryToken(container: container)
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

    // MARK: - Fresh Install Detection

    func isFreshInstall() -> Bool {
        let context = persistentContainer.viewContext
        var count = 0
        context.performAndWait {
            let request = UserCollectionEntity.fetchRequest()
            count = (try? context.count(for: request)) ?? 0
        }
        return count == .zero
    }

    /// 신규 설치 시 호출 — CloudKit Import 완료까지 로컬 UC 생성을 억제
    func markWaitingForFirstImport() {
        isWaitingForFirstImport = true
        os_log(.info, log: .default, "🚀 Marked waiting for first CloudKit import")
    }

    /// Import 대기 플래그 해제 — setupApp() 또는 no-iCloud 경로에서 호출
    func clearWaitingForFirstImport() {
        isWaitingForFirstImport = false
        os_log(.info, log: .default, "🚀 Cleared waiting for first CloudKit import")
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

    // MARK: - Persistent History Change Detection

    /// 컨테이너 초기화 시 현재 히스토리 토큰을 기록하여 이후 변경만 감지
    private func initializeHistoryToken(container: NSPersistentCloudKitContainer) {
        let context = container.newBackgroundContext()
        context.performAndWait {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: nil as NSPersistentHistoryToken?)
            request.resultType = .transactionsOnly
            if let result = try? context.execute(request) as? NSPersistentHistoryResult,
               let transactions = result.result as? [NSPersistentHistoryTransaction],
               let token = transactions.last?.token {
                self._lastHistoryToken.withLock { $0 = token }
            }
        }
    }

    /// Import 완료 후 persistent history를 조회하여 실제 데이터 변경 여부를 확인
    private func hasImportedChanges() -> Bool {
        let token = _lastHistoryToken.withLock { $0 }
        let context = persistentContainer.newBackgroundContext()
        var result = false

        context.performAndWait {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
            request.resultType = .transactionsAndChanges

            guard let historyResult = try? context.execute(request) as? NSPersistentHistoryResult,
                  let transactions = historyResult.result as? [NSPersistentHistoryTransaction] else {
                return
            }

            if let newToken = transactions.last?.token {
                self._lastHistoryToken.withLock { $0 = newToken }
            }

            // author != nil → CloudKit mirroring delegate가 생성한 트랜잭션만 필터
            // (앱 로컬 저장은 author == nil)
            result = transactions.contains { transaction in
                guard transaction.author != nil,
                      let changes = transaction.changes else {
                    return false
                }
                return !changes.isEmpty
            }
        }

        return result
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
                isWaitingForFirstImport = false
                let hasChanges = hasImportedChanges()
                logSyncDiagnostics(phase: "Import-end")
                consolidateUserCollections()
                NotificationCenter.default.post(
                    name: Self.didFinishCloudImport,
                    object: nil,
                    userInfo: hasChanges ? ["hasChanges": true] : nil
                )
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

// MARK: - Sync Diagnostics

extension CoreDataStorage {

    /// CloudKit Import/Export 이벤트 후 데이터 상태를 로깅 (5초 throttle)
    func logSyncDiagnostics(phase: String) {
        let shouldProceed = lastDiagnosticsDate.withLock { lastDate -> Bool in
            let now = Date()
            guard now.timeIntervalSince(lastDate) >= 5 else {
                return false
            }

            lastDate = now
            return true
        }

        guard shouldProceed else {
            os_log(.info, log: .default, "📊 [%{public}@] skipped (throttled)", phase)
            return
        }

        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let entityNames = [
                "UserCollectionEntity", "ItemEntity", "DailyTaskEntity",
                "VillagersLikeEntity", "VillagersHouseEntity", "NPCLikeEntity",
                "VariantCollectionEntity"
            ]

            var counts: [String: Int] = [:]
            for name in entityNames {
                let request = NSFetchRequest<NSManagedObject>(entityName: name)
                counts[name] = (try? context.count(for: request)) ?? -1
            }

            os_log(.info, log: .default,
                   "📊 [%{public}@] UC=%d Items=%d Tasks=%d VLike=%d VHouse=%d NPC=%d Variants=%d",
                   phase,
                   counts["UserCollectionEntity"] ?? -1,
                   counts["ItemEntity"] ?? -1,
                   counts["DailyTaskEntity"] ?? -1,
                   counts["VillagersLikeEntity"] ?? -1,
                   counts["VillagersHouseEntity"] ?? -1,
                   counts["NPCLikeEntity"] ?? -1,
                   counts["VariantCollectionEntity"] ?? -1)

            // UC가 2개 이상일 때만 상세 진단 (중복 탐지)
            let ucCount = counts["UserCollectionEntity"] ?? 0
            guard ucCount > 1 else {
                return
            }

            let ucRequest = UserCollectionEntity.fetchRequest()
            guard let ucResults = try? context.fetch(ucRequest) else {
                return
            }

            for (index, uc) in ucResults.enumerated() {
                let critters = uc.critters?.count ?? 0
                let tasks = uc.dailyTasks?.count ?? 0
                let vLike = uc.villagersLike?.count ?? 0
                let vHouse = uc.villagersHouse?.count ?? 0
                let npcLike = uc.npcLike?.count ?? 0
                let variants = uc.variants?.count ?? 0
                let objectID = uc.objectID.uriRepresentation().lastPathComponent

                // swiftlint:disable:next line_length
                os_log(.info, log: .default, "📊 [%{public}@] UC[%d] id=%{public}@ name=%{private}@ island=%{private}@ | items=%d tasks=%d vLike=%d vHouse=%d npc=%d variants=%d", phase, index, objectID, uc.name ?? "(nil)", uc.islandName ?? "(nil)", critters, tasks, vLike, vHouse, npcLike, variants)
            }
        }
    }
}

// MARK: - UC Consolidation

extension CoreDataStorage {

    /// 중복 UserCollectionEntity를 하나로 통합하고 고아 엔티티를 정리
    func consolidateUserCollections() {
        performBackgroundTask { [weak self] context in
            guard let self else {
                return
            }

            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let request = UserCollectionEntity.fetchRequest()
            let allUCs: [UserCollectionEntity]
            do {
                allUCs = try context.fetch(request)
            } catch {
                os_log(.error, log: .default,
                       "🔧 Consolidation fetch failed: %{public}@",
                       error.localizedDescription)
                return
            }

            guard allUCs.count > 1 else {
                return
            }

            let sorted = allUCs.sorted { self.relationshipCount(of: $0) > self.relationshipCount(of: $1) }
            let keptUC = sorted[0]

            os_log(.info, log: .default,
                   "🔧 Consolidation: %d UCs found, keeping UC with %d relationships",
                   allUCs.count, self.relationshipCount(of: keptUC))

            for orphanUC in sorted.dropFirst() {
                os_log(.info, log: .default,
                       "🔧 Consolidation: reassigning & deleting UC id=%{public}@ (%d relationships)",
                       orphanUC.objectID.uriRepresentation().lastPathComponent,
                       self.relationshipCount(of: orphanUC))
                self.reassignRelationships(from: orphanUC, to: keptUC)
                context.delete(orphanUC)
            }
            context.saveContext()

            self.cleanupOrphanedEntities(in: context)

            os_log(.info, log: .default, "🔧 Consolidation: completed")
        }
    }

    /// orphan UC의 관계 엔티티를 kept UC로 이전 (데이터 손실 방지)
    private func reassignRelationships(
        from source: UserCollectionEntity,
        to destination: UserCollectionEntity
    ) {
        // Note: "userColletion"은 CoreData 모델의 기존 typo (기술 부채)
        let relationships: [(toManyKey: String, inverseKey: String)] = [
            ("critters", "userColletion"),
            ("dailyTasks", "userCollection"),
            ("villagersLike", "userCollection"),
            ("villagersHouse", "userCollection"),
            ("npcLike", "userCollection"),
            ("variants", "userCollection")
        ]

        for (toManyKey, inverseKey) in relationships {
            guard let children = source.value(forKey: toManyKey) as? Set<NSManagedObject> else {
                continue
            }

            for child in children {
                child.setValue(destination, forKey: inverseKey)
            }
        }
    }

    /// UC 관계가 nil인 고아 엔티티를 삭제
    private func cleanupOrphanedEntities(in context: NSManagedObjectContext) {
        // Note: ItemEntity의 inverse relationship이 "userColletion" (typo)인 것은
        // CoreData 모델의 기존 오타. 모델 마이그레이션이 필요하므로 별도 기술 부채로 관리.
        let entityRelMap: [(entity: String, relationship: String)] = [
            ("ItemEntity", "userColletion"),
            ("DailyTaskEntity", "userCollection"),
            ("VillagersLikeEntity", "userCollection"),
            ("VillagersHouseEntity", "userCollection"),
            ("NPCLikeEntity", "userCollection"),
            ("VariantCollectionEntity", "userCollection")
        ]

        var totalOrphans = 0
        for (entity, rel) in entityRelMap {
            let request = NSFetchRequest<NSManagedObject>(entityName: entity)
            request.predicate = NSPredicate(format: "%K == nil", rel)
            if let orphans = try? context.fetch(request), !orphans.isEmpty {
                os_log(.info, log: .default,
                       "🔧 Orphan cleanup: %{public}@ → %d orphans deleted",
                       entity, orphans.count)
                orphans.forEach { context.delete($0) }
                totalOrphans += orphans.count
            }
        }

        if totalOrphans > 0 {
            context.saveContext()
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
                    os_log(.error, log: .default,
                           "CloudKit migration failed: %{public}@ - %{public}@",
                           entityName, error.localizedDescription)
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
            self.relationshipCount(of: lhs) > self.relationshipCount(of: rhs)
        }

        if results.count > 1 {
            os_log(.info, log: .default,
                   "⚠️ getUserCollection: %d UCs found (returning UC with %d relationships)",
                   results.count, self.relationshipCount(of: sorted.first!))
        }

        if let existing = sorted.first {
            return existing
        }

        // 신규 설치 시 CloudKit Import 완료 전에는 UC 생성을 억제하여
        // Export로 인한 iCloud 중복 UC 방지
        if isWaitingForFirstImport {
            os_log(.info, log: .default, "⏳ getUserCollection: No UC found, waiting for CloudKit import — skipping creation")
            throw CoreDataStorageError.notFound
        }

        os_log(.info, log: .default, "⚠️ getUserCollection: No UC found — creating new one")
        return UserCollectionEntity(UserInfo(), context: context)
    }

    private func relationshipCount(of entity: UserCollectionEntity) -> Int {
        let critters: Int = entity.critters?.count ?? 0
        let villagersLike: Int = entity.villagersLike?.count ?? 0
        let villagersHouse: Int = entity.villagersHouse?.count ?? 0
        let dailyTasks: Int = entity.dailyTasks?.count ?? 0
        let npcLike: Int = entity.npcLike?.count ?? 0
        let variants: Int = entity.variants?.count ?? 0
        return critters + villagersLike + villagersHouse + dailyTasks + npcLike + variants
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
