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

    /// Fresh install에서 CloudKit 첫 import 대기가 timeout된 상태.
    /// timeout은 "원격 데이터 없음"이 아니라 "아직 모름"이므로 빈 UC 생성을 막는다.
    private let _isFirstImportTimedOut = OSAllocatedUnfairLock(initialState: false)
    private(set) var isFirstImportTimedOut: Bool {
        get { _isFirstImportTimedOut.withLock { $0 } }
        set { _isFirstImportTimedOut.withLock { $0 = newValue } }
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

    /// 한 번이라도 UserCollectionEntity가 존재했는지 여부 (UserDefaults 기반, 메모리 캐싱)
    /// 이 플래그가 true인데 UC가 0개면, 빈 UC 자동 생성 대신 .notFound를 throw
    /// 초기값은 init에서 주입된 `userDefaults`로부터 읽는다.
    private let _hasEverHadUserCollectionCached: OSAllocatedUnfairLock<Bool>
    private(set) var hasEverHadUserCollection: Bool {
        get { _hasEverHadUserCollectionCached.withLock { $0 } }
        set {
            // UserDefaults I/O는 unfair lock 임계영역 밖에서 수행한다 (잠재적 재진입 트랩 회피).
            let didChange = _hasEverHadUserCollectionCached.withLock { cached -> Bool in
                guard cached != newValue else {
                    return false
                }
                cached = newValue
                return true
            }
            guard didChange else {
                return
            }
            userDefaults.set(newValue, forKey: Self.hasEverHadUserCollectionKey)
        }
    }

    /// 의도적 데이터 초기화 시 호출 — 새 UC 생성을 다시 허용
    func clearHasEverHadUserCollection() {
        hasEverHadUserCollection = false
        Log.info("hasEverHadUserCollection cleared (intentional reset)")
    }

    // MARK: - Recovery Grace Period

    private static let recoveryInitiatedAtKey = "CoreDataStorage_recoveryInitiatedAt"

    /// performCloudKitRecovery 후 재시작했는데 import가 지연되는 상황을
    /// UI/로그에서 구분하기 위한 유예 시간 (10분).
    private static let recoveryGracePeriodSeconds: TimeInterval = 600

    /// 복구 시작 시각 기록 — 재시작 후 grace window 계산에 사용
    func markRecoveryInitiated() {
        userDefaults.set(Date().timeIntervalSince1970, forKey: Self.recoveryInitiatedAtKey)
        Log.info("recovery initiated timestamp recorded (10min grace started)")
    }

    /// Recovery 완료 후 UC가 정상 복구되면 호출하여 플래그 정리
    func clearRecoveryInitiated() {
        userDefaults.removeObject(forKey: Self.recoveryInitiatedAtKey)
    }

    /// 성공한 import로 UC가 실제 복구되었으면 recovery grace 타임스탬프를 정리한다.
    /// UC가 아직 없으면(부분 import) 타임스탬프를 유지해 진단 상태가 남도록 한다.
    private func clearRecoveryInitiatedIfRecovered() {
        guard isWithinRecoveryGracePeriod else {
            return
        }

        persistentContainer.performBackgroundTask { [weak self] context in
            guard let owner = self else {
                return
            }

            let count = (try? context.count(for: UserCollectionEntity.fetchRequest())) ?? 0
            guard count > 0 else {
                return
            }

            owner.clearRecoveryInitiated()
            Log.info("recovery grace cleared — UC restored by successful import")
        }
    }

    /// 복구 시작 후 grace period 내인지 확인 — 상태 표시에만 사용하고, UC 생성 허용에는 사용하지 않는다.
    var isWithinRecoveryGracePeriod: Bool {
        let timestamp = userDefaults.double(forKey: Self.recoveryInitiatedAtKey)
        guard timestamp > 0 else {
            return false
        }
        let elapsed = Date().timeIntervalSince1970 - timestamp
        if elapsed < 0 || elapsed > Self.recoveryGracePeriodSeconds {
            // 만료 시 자동 정리
            userDefaults.removeObject(forKey: Self.recoveryInitiatedAtKey)
            return false
        }
        return true
    }

    /// 첫 Import 완료 후 UC 생성/기본 데이터 생성을 유예하는 시간 (초)
    private static let gracePeriodSeconds: TimeInterval = 120

    /// 첫 Import 완료 후 grace period 내인지 확인
    private var isWithinGracePeriod: Bool {
        guard let firstImportDate = _firstImportCompletedAt.withLock({ $0 }) else {
            return false
        }
        return Date().timeIntervalSince(firstImportDate) < Self.gracePeriodSeconds
    }

    /// Import 또는 sync reset 진행 중이거나, grace period 내인지 확인
    /// DailyTask 등 외부 Storage에서도 기본값 생성 억제 판단에 사용
    /// 주의: hasEverHadUserCollection은 여기에 포함하지 않음 — 그 플래그는 getUserCollection()에서만 사용
    ///       여기에 포함하면 기존 유저의 DailyTask 자동 생성이 영구적으로 차단됨
    var shouldSuppressDataCreation: Bool {
        isWaitingForFirstImport
            || isImportInProgress
            || isSyncResetInProgress
            || isFirstImportTimedOut
            || isWithinGracePeriod
    }

    /// 반복되는 sync 실패로 사용자가 "빈 컬렉션" 보호 모드에 갇힌 상태인지.
    /// UC가 없는데 생성이 억제 중이거나 known-user 보호로 차단된 경우 true.
    /// SceneDelegate가 동기화 실패 시 보호 모드 안내 노출 여부를 판단할 때 사용한다.
    var isAwaitingCloudDataWithoutCollection: Bool {
        guard shouldSuppressDataCreation || hasEverHadUserCollection else {
            return false
        }

        return isFreshInstall()
    }

    // MARK: - Private API Notification Names (fragile)
    // These notification names are undocumented and may change without notice.
    // Verified working on iOS 16–18. Remove if Apple provides a public API.
    enum SyncResetNotification {
        static let willReset = Notification.Name("NSCloudKitMirroringDelegateWillResetSyncNotificationName")
        static let didReset = Notification.Name("NSCloudKitMirroringDelegateDidResetSyncNotificationName")
    }

    private let injectedPersistentContainer: NSPersistentCloudKitContainer?

    /// 동기화 영속 플래그(known-user/recovery)의 저장소. production은 `.standard`,
    /// 테스트는 격리된 suite를 주입해 실기기의 실제 앱 상태를 오염시키지 않는다.
    private let userDefaults: UserDefaults

    private init(
        persistentContainer: NSPersistentCloudKitContainer? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.injectedPersistentContainer = persistentContainer
        self.userDefaults = userDefaults
        self._hasEverHadUserCollectionCached = OSAllocatedUnfairLock(
            initialState: userDefaults.bool(forKey: Self.hasEverHadUserCollectionKey)
        )
    }

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        if let injectedPersistentContainer {
            return injectedPersistentContainer
        }

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
        Log.info("markWaitingForFirstImport (fresh install path)")
        Log.setContext(Log.Key.isFreshInstall, true)
    }

    /// Import 대기 플래그 해제 — setupApp() 또는 no-iCloud 경로에서 호출
    func clearWaitingForFirstImport() {
        isWaitingForFirstImport = false
        isFirstImportTimedOut = false
        Log.info("clearWaitingForFirstImport")
    }

    enum FirstImportWaitCompletionReason: Equatable {
        case importArrived
        case noICloud
        case timeout
    }

    /// Fresh install 첫 CloudKit import 대기 종료.
    /// timeout은 데이터 없음의 증거가 아니므로 UC 생성을 계속 억제한다.
    func completeFirstImportWait(reason: FirstImportWaitCompletionReason) {
        // timedOut 플래그를 먼저 확정한 뒤 waiting을 해제한다. 순서를 뒤집으면 두 플래그가
        // 모두 false가 되는 찰나에 shouldSuppressDataCreation이 잠깐 풀리는 TOCTOU 윈도우가
        // 생긴다 (timeout 경로). 이 순서면 억제는 항상 fail-safe하게 유지된다.
        switch reason {
        case .importArrived, .noICloud:
            isFirstImportTimedOut = false
        case .timeout:
            isFirstImportTimedOut = lastSuccessfulImportDate == nil
        }
        isWaitingForFirstImport = false
        Log.info("completeFirstImportWait reason=\(reason)")
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
        Log.warning("sync reset WillReset — Change Token Expired, orphan cleanup suppressed")
        Log.event(.tokenExpired)
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
            let didSucceed = event.error == nil
            if let error = event.error {
                os_log(.error, log: .default, "CloudKit %{public}@ failed: %{public}@", type, error.localizedDescription)
                postSyncFailureIfNeeded(error)
            } else {
                os_log(.info, log: .default, "CloudKit %{public}@ succeeded", type)
                // 동기화 성공 시각 기록 (설정 화면 표시용)
                if event.type == .export {
                    lastSuccessfulExportDate = Date()
                }
            }
            if event.type == .import {
                finishCloudImport(succeeded: didSucceed)
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

    private func finishCloudImport(succeeded: Bool) {
        isImportInProgress = false

        guard succeeded else {
            // Failed import means CloudKit data is still unknown. Keep waiting/timeout/reset
            // suppression flags so the app cannot create and export an empty UC after grace.
            // _exportRetryCount is export-only (never incremented by import), so the success
            // path's reset is intentionally absent here.
            logSyncDiagnostics(phase: "Import-failed", throttled: false)
            return
        }

        lastSuccessfulImportDate = Date()
        isWaitingForFirstImport = false
        isFirstImportTimedOut = false
        isSyncResetInProgress = false
        _exportRetryCount.withLock { $0 = 0 }

        _firstImportCompletedAt.withLock { date in
            if date == nil { date = Date() }
        }

        clearRecoveryInitiatedIfRecovered()

        let hasChanges = hasImportedChanges()
        logSyncDiagnostics(phase: "Import-end")

        // Import 후 자동 consolidation/orphan cleanup이 로컬 데이터를 삭제하는 버그로
        // 제거됨 — 사용자가 설정에서 명시적으로 실행할 때만 돌아간다.

        NotificationCenter.default.post(
            name: Self.didFinishCloudImport,
            object: nil,
            userInfo: hasChanges ? ["hasChanges": true] : nil
        )
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

        Log.warning("cloud sync failed reason=\(reason) code=\(nsError.code)")
        Log.event(.cloudSyncFailed, parameters: [
            Log.Param.reason: reason,
            Log.Param.code: nsError.code
        ])
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

    // MARK: - Entity Count Helper

    private static let entityNames = [
        "UserCollectionEntity", "ItemEntity", "DailyTaskEntity",
        "VillagersLikeEntity", "VillagersHouseEntity", "NPCLikeEntity",
        "VariantCollectionEntity"
    ]

    /// 모든 엔티티의 레코드 수를 한 번에 조회 (logSyncDiagnostics, fetchSyncStatus 공용)
    private func entityCounts(in context: NSManagedObjectContext) -> [String: Int] {
        var counts: [String: Int] = [:]
        for name in Self.entityNames {
            let request = NSFetchRequest<NSManagedObject>(entityName: name)
            counts[name] = (try? context.count(for: request)) ?? -1
        }
        return counts
    }

    /// CloudKit 이벤트 후 데이터 상태를 os_log에 기록하고 Crashlytics 세션 스냅샷을 갱신한다.
    /// 한 번의 background fetch로 두 용도를 모두 처리.
    ///
    /// - Parameters:
    ///   - phase: 호출 지점을 식별하는 라벨 (예: "Import-end", "UC-missing")
    ///   - throttled: true면 5초 내 재호출 시 skip. UC-missing처럼 즉시 컨텍스트가 필요한 경우 false.
    func logSyncDiagnostics(phase: String, throttled: Bool = true) {
        if throttled {
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
        }

        persistentContainer.performBackgroundTask { [weak self] context in
            guard let owner = self else {
                return
            }

            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let counts = owner.entityCounts(in: context)
            let ucCount = counts["UserCollectionEntity"] ?? -1
            let itemCount = counts["ItemEntity"] ?? -1

            os_log(.info, log: .default,
                   "📊 [%{public}@] UC=%d Items=%d Tasks=%d VLike=%d VHouse=%d NPC=%d Variants=%d",
                   phase,
                   ucCount, itemCount,
                   counts["DailyTaskEntity"] ?? -1,
                   counts["VillagersLikeEntity"] ?? -1,
                   counts["VillagersHouseEntity"] ?? -1,
                   counts["NPCLikeEntity"] ?? -1,
                   counts["VariantCollectionEntity"] ?? -1)

            Log.snapshot(Log.Snapshot(
                ucCount: ucCount,
                itemCount: itemCount,
                taskCount: counts["DailyTaskEntity"] ?? -1,
                villagerCount: (counts["VillagersLikeEntity"] ?? 0) + (counts["VillagersHouseEntity"] ?? 0),
                hasEverHadUC: owner.hasEverHadUserCollection,
                isFreshInstall: nil,
                isWaitingForFirstImport: owner.isWaitingForFirstImport,
                isFirstImportTimedOut: owner.isFirstImportTimedOut,
                isImportInProgress: owner.isImportInProgress,
                isSyncResetInProgress: owner.isSyncResetInProgress,
                isWithinRecoveryGracePeriod: owner.isWithinRecoveryGracePeriod,
                lastImportDate: owner.lastSuccessfulImportDate,
                lastExportDate: owner.lastSuccessfulExportDate
            ))

            // UC가 2개 이상일 때만 상세 진단 (중복 탐지)
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

            let counts = self.entityCounts(in: context)
            let totalRecords = (counts["ItemEntity"] ?? 0)
                + (counts["DailyTaskEntity"] ?? 0)
                + (counts["VillagersLikeEntity"] ?? 0)
                + (counts["VillagersHouseEntity"] ?? 0)

            let info = SyncStatusInfo(
                hasUserCollection: (counts["UserCollectionEntity"] ?? 0) > 0,
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

    /// 사용자가 설정 화면에서 "중복/고아 데이터 정리" 버튼을 눌렀을 때 호출.
    /// 작업 완료 후 main queue로 completion 호출.
    func consolidateUserCollectionsManually(completion: @escaping () -> Void) {
        performBackgroundTask { [weak self] context in
            self?.consolidateAndCleanup(in: context)
            DispatchQueue.main.async { completion() }
        }
    }

    /// 중복 UserCollectionEntity를 하나로 통합하고 고아 엔티티를 정리
    func consolidateUserCollections() {
        performBackgroundTask { [weak self] context in
            self?.consolidateAndCleanup(in: context)
        }
    }

    private func consolidateAndCleanup(in context: NSManagedObjectContext) {
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

        if allUCs.count > 1 {
            let sorted = allUCs.sorted { self.relationshipCount(of: $0) > self.relationshipCount(of: $1) }
            let keptUC = sorted[0]

            os_log(.info, log: .default,
                   "🔧 Consolidation: %d UCs found, keeping UC with %d relationships",
                   allUCs.count, self.relationshipCount(of: keptUC))

            Log.info("consolidating \(allUCs.count) UCs, kept relationships=\(self.relationshipCount(of: keptUC))")
            Log.event(.ucConsolidated, parameters: [
                Log.Param.ucTotal: allUCs.count,
                Log.Param.keptRelationships: self.relationshipCount(of: keptUC)
            ])

            for orphanUC in sorted.dropFirst() {
                os_log(.info, log: .default,
                       "🔧 Consolidation: reassigning & deleting UC id=%{public}@ (%d relationships)",
                       orphanUC.objectID.uriRepresentation().lastPathComponent,
                       self.relationshipCount(of: orphanUC))
                self.reassignRelationships(from: orphanUC, to: keptUC)
                context.delete(orphanUC)
            }
            context.saveContext()
        }

        self.cleanupOrphanedEntities(in: context)

        os_log(.info, log: .default, "🔧 Consolidation: completed")
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
        // Import/sync reset 진행 중이거나 import 완료 직후 grace period에는 cleanup 건너뜀
        // — CloudKit이 relationship을 비동기로 해소하므로 import가 끝난 뒤에도
        //   일시적으로 orphan처럼 보일 수 있음 (grace period가 존재하는 이유와 동일)
        guard !isImportInProgress, !isSyncResetInProgress, !isWithinGracePeriod else {
            os_log(.info, log: .default, "🔧 Orphan cleanup skipped — sync in progress or within grace period")
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
                // 데이터 삭제는 항상 감사 대상 — Crashlytics 비치명 에러로 승격
                let userInfo: [String: Any] = [
                    Log.Param.entity: entity,
                    Log.Param.deleted: orphans.count,
                    Log.Param.total: totalCount
                ]
                Log.event(.orphanCleanup, parameters: userInfo)
                Log.error(
                    name: "OrphanCleanupDelete",
                    reason: "\(entity) \(orphans.count)/\(totalCount) deleted",
                    userInfo: userInfo
                )
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
        // 4. fresh install 첫 import 대기가 timeout됨 (CloudKit 데이터 유무가 아직 불명확)
        // 5. 첫 Import 완료 후 120초 유예 (relationship 해소 시간 확보)
        // 6. 기존 유저 — 이전에 UC가 존재했으므로, CloudKit re-import 대기 필요
        if isWaitingForFirstImport || isImportInProgress || isSyncResetInProgress || isFirstImportTimedOut {
            Log.info(
                "getUserCollection: No UC — skipping "
                    + "(waiting=\(isWaitingForFirstImport), importing=\(isImportInProgress), "
                    + "reset=\(isSyncResetInProgress), timedOut=\(isFirstImportTimedOut))"
            )
            Log.event(.ucCreationSuppressed, parameters: [
                Log.Param.reason: SuppressionReason.syncInProgress.rawValue,
                Log.Param.waiting: isWaitingForFirstImport.description,
                Log.Param.importing: isImportInProgress.description,
                Log.Param.reset: isSyncResetInProgress.description,
                Log.Param.timedOut: isFirstImportTimedOut.description
            ])
            throw CoreDataStorageError.notFound
        }

        if isWithinGracePeriod {
            Log.info("getUserCollection: No UC, within \(Int(Self.gracePeriodSeconds))s grace period — skipping")
            Log.event(.ucCreationSuppressed, parameters: [
                Log.Param.reason: SuppressionReason.gracePeriod.rawValue
            ])
            throw CoreDataStorageError.notFound
        }

        // 기존 유저인데 UC가 0개 → CloudKit 미러 재구성 또는 re-import 대기 상태
        // 빈 UC를 생성하면 CloudKit에 빈 데이터가 Export되어 기존 데이터를 오염시킬 수 있음
        if hasEverHadUserCollection {
            // 핵심 데이터 유실 증상: "기존 유저인데 UC가 사라짐".
            // 3.2.0 이후 클레임의 주 증상으로 추정되는 상태.
            Log.warning("UC missing but hasEverHadUC=true — user data appears reset, blocking empty UC to protect cloud")
            Log.event(.ucMissing)
            logSyncDiagnostics(phase: "UC-missing", throttled: false)
            Log.error(
                name: "UserCollectionMissing",
                reason: "hasEverHadUserCollection=true but UC count=0",
                userInfo: [
                    Log.Param.waiting: isWaitingForFirstImport,
                    Log.Param.importing: isImportInProgress,
                    Log.Param.reset: isSyncResetInProgress,
                    Log.Param.recoveryGrace: isWithinRecoveryGracePeriod
                ]
            )
            throw CoreDataStorageError.notFound
        }

        Log.info("UC created for fresh user")
        Log.event(.ucCreated, parameters: [Log.Param.path: UCCreationPath.freshUser.rawValue])
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

#if DEBUG
// MARK: - Testing
extension CoreDataStorage {
    convenience init(
        testingPersistentContainer: NSPersistentCloudKitContainer,
        userDefaults: UserDefaults = .standard
    ) {
        self.init(persistentContainer: testingPersistentContainer, userDefaults: userDefaults)
    }

    func markImportInProgressForTesting() {
        isImportInProgress = true
    }

    func markSyncResetInProgressForTesting() {
        isSyncResetInProgress = true
    }

    func finishCloudImportForTesting(succeeded: Bool) {
        finishCloudImport(succeeded: succeeded)
    }
}
#endif

private enum UCCreationPath: String {
    case freshUser = "fresh_user"
}

private enum SuppressionReason: String {
    case syncInProgress = "sync_in_progress"
    case gracePeriod = "grace_period"
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
