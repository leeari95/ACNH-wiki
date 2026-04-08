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

    /// CloudKit Import가 진행 중인지 추적 — orphan cleanup 억제에 사용
    private let _isImportInProgress = OSAllocatedUnfairLock(initialState: false)
    private(set) var isImportInProgress: Bool {
        get { _isImportInProgress.withLock { $0 } }
        set { _isImportInProgress.withLock { $0 = newValue } }
    }

    /// Change Token Expired로 인한 sync reset 진행 중 — 모든 cleanup 억제
    private let _isSyncResetInProgress = OSAllocatedUnfairLock(initialState: false)
    private(set) var isSyncResetInProgress: Bool {
        get { _isSyncResetInProgress.withLock { $0 } }
        set { _isSyncResetInProgress.withLock { $0 = newValue } }
    }

    /// 첫 번째 Import 완료 시점 — grace period 계산에 사용
    private let _firstImportCompletedAt = OSAllocatedUnfairLock<Date?>(initialState: nil)

    /// Export 재시도 횟수
    private let _exportRetryCount = OSAllocatedUnfairLock(initialState: 0)

    /// Consolidation 5초 지연 타이머 — 새 import 시 이전 타이머 취소용
    private var consolidationWorkItem: DispatchWorkItem?

    /// 마지막 CloudKit Import 성공 시각 — 동기화 상태 표시에 사용
    private let _lastSuccessfulImportDate = OSAllocatedUnfairLock<Date?>(initialState: nil)
    var lastSuccessfulImportDate: Date? {
        get { _lastSuccessfulImportDate.withLock { $0 } }
        set { _lastSuccessfulImportDate.withLock { $0 = newValue } }
    }

    /// 마지막 CloudKit Export 성공 시각 — 동기화 상태 표시에 사용
    private let _lastSuccessfulExportDate = OSAllocatedUnfairLock<Date?>(initialState: nil)
    var lastSuccessfulExportDate: Date? {
        get { _lastSuccessfulExportDate.withLock { $0 } }
        set { _lastSuccessfulExportDate.withLock { $0 = newValue } }
    }

    // MARK: - Known User Flag

    private static let hasEverHadUserCollectionKey = "CoreDataStorage_hasEverHadUserCollection"

    /// 한 번이라도 UserCollectionEntity가 존재했는지 여부 (UserDefaults 기반)
    /// 이 플래그가 true인데 UC가 0개면, 빈 UC 자동 생성 대신 .notFound를 throw
    private(set) var hasEverHadUserCollection: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasEverHadUserCollectionKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasEverHadUserCollectionKey) }
    }

    /// 의도적 데이터 초기화 시 호출 — 새 UC 생성을 다시 허용
    func clearHasEverHadUserCollection() {
        hasEverHadUserCollection = false
        os_log(.info, log: .default, "🛡️ hasEverHadUserCollection cleared (intentional reset)")
    }

    /// Import 또는 sync reset 진행 중이거나, grace period 내인지 확인
    /// DailyTask 등 외부 Storage에서도 기본값 생성 억제 판단에 사용
    /// 주의: hasEverHadUserCollection은 여기에 포함하지 않음 — 그 플래그는 getUserCollection()에서만 사용
    ///       여기에 포함하면 기존 유저의 DailyTask 자동 생성이 영구적으로 차단됨
    var shouldSuppressDataCreation: Bool {
        if isWaitingForFirstImport || isImportInProgress || isSyncResetInProgress {
            return true
        }
        if let firstImportDate = _firstImportCompletedAt.withLock({ $0 }),
           Date().timeIntervalSince(firstImportDate) < 120 {
            return true
        }
        return false
    }

    // MARK: - Private API Notification Names (fragile)
    // These notification names are undocumented and may change without notice.
    // Verified working on iOS 16–18. Remove if Apple provides a public API.
    private enum SyncResetNotification {
        static let willReset = Notification.Name("NSCloudKitMirroringDelegateWillResetSyncNotificationName")
        static let didReset = Notification.Name("NSCloudKitMirroringDelegateDidResetSyncNotificationName")
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
        observeSyncReset()
    }

    // MARK: - Sync Reset Detection (Change Token Expired)

    private func observeSyncReset() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSyncWillReset(_:)),
            name: SyncResetNotification.willReset,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSyncDidReset(_:)),
            name: SyncResetNotification.didReset,
            object: nil
        )
    }

    @objc private func handleSyncWillReset(_ notification: Notification) {
        isSyncResetInProgress = true
        os_log(.info, log: .default, "🔄 Sync reset detected (WillReset) — orphan cleanup suppressed")
    }

    @objc private func handleSyncDidReset(_ notification: Notification) {
        os_log(.info, log: .default, "🔄 Sync reset completed (DidReset) — waiting for next import cycle")
        // DidReset 후 다음 Import가 완료되면 isSyncResetInProgress를 해제
        // handleCloudKitEvent의 import 종료 처리에서 해제됨
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
                // 동기화 성공 시각 기록 (설정 화면 표시용)
                if event.type == .import {
                    lastSuccessfulImportDate = Date()
                } else if event.type == .export {
                    lastSuccessfulExportDate = Date()
                }
            }
            if event.type == .import {
                isImportInProgress = false
                isWaitingForFirstImport = false
                isSyncResetInProgress = false
                _exportRetryCount.withLock { $0 = 0 }

                _firstImportCompletedAt.withLock { date in
                    if date == nil { date = Date() }
                }

                let hasChanges = hasImportedChanges()
                logSyncDiagnostics(phase: "Import-end")

                // CloudKit이 relationship을 해소할 시간을 확보하기 위해 5초 지연
                // 이전 타이머가 있으면 취소하여 중복 실행 방지
                consolidationWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.consolidateUserCollections()
                }
                consolidationWorkItem = workItem
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5, execute: workItem)

                NotificationCenter.default.post(
                    name: Self.didFinishCloudImport,
                    object: nil,
                    userInfo: hasChanges ? ["hasChanges": true] : nil
                )
            }
            if event.type == .export {
                if event.error != nil {
                    retryExportAfterMergeError()
                } else {
                    _exportRetryCount.withLock { $0 = 0 }
                }
            }
        } else {
            os_log(.info, log: .default, "CloudKit %{public}@ started", type)
            if event.type == .import {
                isImportInProgress = true
                NotificationCenter.default.post(name: Self.didStartCloudImport, object: nil)
            }
        }
    }

    // MARK: - Export Retry

    private func retryExportAfterMergeError() {
        let retryCount = _exportRetryCount.withLock { count -> Int in
            count += 1
            return count
        }

        guard retryCount <= 3 else {
            os_log(.error, log: .default, "Export retry limit reached (%d) — giving up", retryCount)
            return
        }

        let delay = Double(retryCount) * 5.0
        os_log(.info, log: .default, "Export failed — scheduling retry %d in %.0fs", retryCount, delay)

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.persistentContainer.performBackgroundTask { context in
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                let request = UserCollectionEntity.fetchRequest()
                guard let ucs = try? context.fetch(request), !ucs.isEmpty else {
                    return
                }
                // UC attribute를 re-touch하여 CloudKit export 유도
                for uc in ucs {
                    let name = uc.name
                    uc.name = name
                }
                context.saveContext()
                os_log(.info, log: .default, "Export retry %d: re-touched %d UC(s)", retryCount, ucs.count)
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

    /// 설정 화면에 표시할 동기화 상태 정보를 조회
    func fetchSyncStatus(completion: @escaping (SyncStatusInfo) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let ucCount = (try? context.count(for: UserCollectionEntity.fetchRequest())) ?? 0
            let itemCount = (try? context.count(for: NSFetchRequest<NSManagedObject>(entityName: "ItemEntity"))) ?? 0
            let taskCount = (try? context.count(for: NSFetchRequest<NSManagedObject>(entityName: "DailyTaskEntity"))) ?? 0
            let vLikeCount = (try? context.count(for: NSFetchRequest<NSManagedObject>(entityName: "VillagersLikeEntity"))) ?? 0
            let vHouseCount = (try? context.count(for: NSFetchRequest<NSManagedObject>(entityName: "VillagersHouseEntity"))) ?? 0

            let totalRecords = itemCount + taskCount + vLikeCount + vHouseCount

            let info = SyncStatusInfo(
                hasUserCollection: ucCount > 0,
                totalRecordCount: totalRecords,
                lastImportDate: self.lastSuccessfulImportDate,
                lastExportDate: self.lastSuccessfulExportDate,
                isSyncing: self.isImportInProgress || self.isSyncResetInProgress
            )

            DispatchQueue.main.async {
                completion(info)
            }
        }
    }
}

/// 동기화 상태 정보 모델
struct SyncStatusInfo {
    let hasUserCollection: Bool
    let totalRecordCount: Int
    let lastImportDate: Date?
    let lastExportDate: Date?
    let isSyncing: Bool

    var lastSyncDate: Date? {
        [lastImportDate, lastExportDate].compactMap { $0 }.max()
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
        // Import 또는 sync reset 진행 중에는 cleanup 건너뜀
        // — CloudKit이 relationship을 비동기로 해소하므로 일시적으로 orphan처럼 보일 수 있음
        guard !isImportInProgress, !isSyncResetInProgress else {
            os_log(.info, log: .default, "🔧 Orphan cleanup skipped — sync in progress")
            return
        }

        let ucCount = (try? context.count(for: UserCollectionEntity.fetchRequest())) ?? 0
        guard ucCount > 0 else {
            os_log(.info, log: .default, "🔧 Orphan cleanup skipped — no UC exists")
            return
        }

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
            // Count-first: 객체를 메모리에 올리기 전에 수량만 확인
            let orphanCountRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
            orphanCountRequest.predicate = NSPredicate(format: "%K == nil", rel)
            let orphanCount = (try? context.count(for: orphanCountRequest)) ?? 0
            guard orphanCount > 0 else { continue }

            let totalCount = (try? context.count(for: NSFetchRequest<NSManagedObject>(entityName: entity))) ?? 0

            // 전체 레코드가 모두 orphan이면 삭제하지 않음 — 데이터 유실 방지
            if orphanCount == totalCount {
                os_log(.error, log: .default,
                       "🔧 Orphan cleanup: ALL %{public}@ are orphans (%d) — SKIPPING to protect data",
                       entity, orphanCount)
                continue
            }

            // 안전 확인 통과 후에만 실제 객체를 fetch하여 삭제
            if let orphans = try? context.fetch(orphanCountRequest) {
                os_log(.info, log: .default,
                       "🔧 Orphan cleanup: %{public}@ → %d orphans / %d total deleted",
                       entity, orphans.count, totalCount)
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
            // UC가 존재하면 "기존 유저" 플래그를 기록
            if !hasEverHadUserCollection {
                hasEverHadUserCollection = true
            }
            return existing
        }

        // UC가 없을 때 새 UC 생성을 억제하는 조건들:
        // 1. Import 대기 중 (신규 설치 시 CloudKit Import 완료 전)
        // 2. Import 진행 중 (timeout 후에도 import가 아직 끝나지 않은 경우)
        // 3. Sync reset 진행 중 (Change Token Expired 후 re-import 대기)
        // 4. 첫 Import 완료 후 120초 유예 (relationship 해소 시간 확보)
        // 5. 기존 유저 — 이전에 UC가 존재했으므로, CloudKit re-import 대기 필요
        if isWaitingForFirstImport || isImportInProgress || isSyncResetInProgress {
            os_log(.info, log: .default,
                   "⏳ getUserCollection: No UC found — skipping creation (waiting=%{public}@, importing=%{public}@, reset=%{public}@)",
                   isWaitingForFirstImport.description, isImportInProgress.description, isSyncResetInProgress.description)
            throw CoreDataStorageError.notFound
        }

        if let firstImportDate = _firstImportCompletedAt.withLock({ $0 }),
           Date().timeIntervalSince(firstImportDate) < 120 {
            os_log(.info, log: .default, "⏳ getUserCollection: No UC found, within grace period (120s) — skipping creation")
            throw CoreDataStorageError.notFound
        }

        // 기존 유저인데 UC가 0개 → CloudKit 미러 재구성 또는 re-import 대기 상태
        // 빈 UC를 생성하면 CloudKit에 빈 데이터가 Export되어 기존 데이터를 오염시킬 수 있음
        if hasEverHadUserCollection {
            os_log(.error, log: .default,
                   "🛡️ getUserCollection: No UC found but hasEverHadUserCollection=true — blocking empty UC creation to protect cloud data")
            throw CoreDataStorageError.notFound
        }

        os_log(.info, log: .default, "⚠️ getUserCollection: No UC found (fresh user) — creating new one")
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

// MARK: - Data Recovery (TEMPORARY: Recovery)

extension CoreDataStorage {

    /// TEMPORARY: Recovery — 안정화 후 제거 예정
    enum RecoveryError: LocalizedError {
        case iCloudNotAvailable
        case storeNotFound

        var errorDescription: String? {
            switch self {
            case .iCloudNotAvailable: return "iCloud is not available"
            case .storeNotFound: return "CoreData store not found"
            }
        }
    }

    /// TEMPORARY: Recovery — 로컬 store 파일을 삭제하고 앱 재시작 시 CloudKit에서 전체 재import 유도
    /// store를 런타임에 재등록하면 CloudKit 옵션이 누락되므로, 파일만 삭제하고 재시작을 안내한다.
    func performCloudKitRecovery(completion: @escaping (Result<Void, Error>) -> Void) {
        checkiCloudAccountStatus { [weak self] status in
            guard status == .available else {
                completion(.failure(RecoveryError.iCloudNotAvailable))
                return
            }
            guard let self else { return }

            guard let storeDescription = self.persistentContainer.persistentStoreDescriptions.first,
                  let storeURL = storeDescription.url else {
                completion(.failure(RecoveryError.storeNotFound))
                return
            }

            do {
                // 기존 store 분리
                let coordinator = self.persistentContainer.persistentStoreCoordinator
                if let store = coordinator.persistentStore(for: storeURL) {
                    try coordinator.remove(store)
                }

                // Store 파일 삭제 — fileExists 대신 직접 시도 + 부재 에러 무시 (TOCTOU 방지)
                let fileManager = FileManager.default
                let storePath = storeURL.path
                for suffix in ["", "-shm", "-wal"] {
                    do {
                        try fileManager.removeItem(atPath: storePath + suffix)
                    } catch let error as NSError where error.code == NSFileNoSuchFileError {
                        // 파일이 이미 없음 — 정상
                    }
                }

                // ckAssets 폴더 삭제
                let ckAssetsURL = storeURL.deletingLastPathComponent()
                    .appendingPathComponent("ckAssets")
                do {
                    try fileManager.removeItem(at: ckAssetsURL)
                } catch let error as NSError where error.code == NSFileNoSuchFileError {
                    // 폴더가 이미 없음 — 정상
                }

                // migration flag 유지 — 재시작 시 re-export 중복 방지
                UserDefaults.standard.set(true, forKey: "didMigrateExistingDataToCloudKit_v2")

                // 기존 유저 플래그 유지 — 재시작 후 CloudKit re-import 전까지 빈 UC 생성 방지
                // (복구 = 기존 유저이므로 true 유지가 올바름)

                os_log(.info, log: .default, "🔄 Recovery: store files deleted — app restart required for CloudKit re-import")
                completion(.success(()))
            } catch {
                os_log(.error, log: .default, "🔄 Recovery failed: %{public}@", error.localizedDescription)
                completion(.failure(error))
            }
        }
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
