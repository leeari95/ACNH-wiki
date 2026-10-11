//
//  SafetySnapshotService.swift
//  Animal-Crossing-Wiki
//
//  Documents/local_safety_snapshot.plist에 최신 UC 스냅샷을 유지.
//  iOS의 NSCloudKitMirroringDelegate가 로컬 store를 purge하더라도 이 파일은 건드리지 않으므로
//  다음 앱 시작 시 복원 옵션을 사용자에게 제공할 수 있다.
//

import Foundation
import CoreData
import os

final class SafetySnapshotService {

    static let shared = SafetySnapshotService()

    // MARK: - File Location

    private static let fileName = "local_safety_snapshot.plist"
    private static let snapshotFileProtection: FileProtectionType = .completeUntilFirstUserAuthentication

    var snapshotURL: URL {
        guard let directory = snapshotDirectoryProvider() else {
            fatalError("Safety snapshot directory unavailable")
        }
        return directory.appendingPathComponent(Self.fileName)
    }

    var snapshotExists: Bool {
        FileManager.default.fileExists(atPath: snapshotURL.path)
    }

    // MARK: - Lightweight Metadata Cache
    //
    // readMetadata()가 3MB+ 스냅샷을 매번 unarchive하지 않도록,
    // 스냅샷 저장 시점에 createdAt/childCount만 UserDefaults에 별도로 기록한다.
    // UserDefaults가 비어있으면 fallback으로 파일을 unarchive한다 (예: 마이그레이션 첫 실행).

    private static let metadataCreatedAtKey = "SafetySnapshot_lastCreatedAt"
    private static let metadataChildCountKey = "SafetySnapshot_lastChildCount"

    // MARK: - Debounced Save

    /// 연속된 CoreData 저장을 합치기 위한 지연 시간.
    /// 너무 짧으면 매 수집마다 디스크 I/O, 너무 길면 최근 변경이 스냅샷에 없을 위험.
    private static let debounceSeconds: TimeInterval = 30

    private let queue = DispatchQueue(label: "app.safety.snapshot", qos: .utility)

    /// CoreData 저장 알림(임의 스레드)·main 스레드·sync-reset 알림이 동시에 접근하므로 lock으로 보호
    private let _pendingWorkItem = OSAllocatedUnfairLock<DispatchWorkItem?>(initialState: nil)
    private var observers: [NSObjectProtocol] = []
    private let containerProvider: () -> NSPersistentContainer
    private let snapshotDirectoryProvider: () -> URL?
    private let fileAttributeSetter: (URL, [FileAttributeKey: Any]) throws -> Void
    /// 메타데이터 캐시·reset hold 저장소. production은 `.standard`, 테스트는 격리된 suite를 주입한다.
    private let userDefaults: UserDefaults

    #if DEBUG
    /// 테스트 전용 fault-injection seam. `restore()`가 기존 데이터를 wipe한 직후,
    /// 스냅샷을 적용하기 직전에 호출한다. production 빌드에는 컴파일되지 않으므로
    /// 복원 경로에 죽은 코드가 남지 않는다.
    var beforeApplyingSnapshotForTesting: ((NSManagedObjectContext) throws -> Void)?
    #endif

    init(
        containerProvider: @escaping () -> NSPersistentContainer = { CoreDataStorage.shared.persistentContainer },
        snapshotDirectoryProvider: @escaping () -> URL? = {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        },
        fileAttributeSetter: @escaping (URL, [FileAttributeKey: Any]) throws -> Void = { url, attributes in
            try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
        },
        userDefaults: UserDefaults = .standard
    ) {
        self.containerProvider = containerProvider
        self.snapshotDirectoryProvider = snapshotDirectoryProvider
        self.fileAttributeSetter = fileAttributeSetter
        self.userDefaults = userDefaults
    }

    private var container: NSPersistentContainer {
        containerProvider()
    }

    /// 앱 시작 시 1회 호출 — 다음 이벤트에 대해 모두 스냅샷 작성을 예약:
    /// 1. 로컬 context save (사용자 편집)
    /// 2. CloudKit Import 완료 (원격 기기의 변경을 수신)
    /// 3. 원격 persistent store 변경 알림
    /// 4. CloudKit Sync Reset 임박 (iOS가 로컬 purge 직전에 마지막 flush + reset hold 설정)
    /// 또한 즉시 **initial snapshot**을 비동기로 작성하여, 이번 세션 중 아무 편집이 없더라도
    /// 최신 상태의 백업이 Documents/에 존재하도록 보장한다.
    func startObserving() {
        stopObserving()

        let psc = container.persistentStoreCoordinator
        let saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let ctx = notification.object as? NSManagedObjectContext,
                  ctx.persistentStoreCoordinator === psc else {
                return
            }
            self?.scheduleSnapshot()
        }
        observers.append(saveObserver)

        let importObserver = NotificationCenter.default.addObserver(
            forName: CoreDataStorage.didFinishCloudImport, object: nil, queue: nil
        ) { [weak self] _ in self?.scheduleSnapshot() }
        observers.append(importObserver)

        let remoteObserver = NotificationCenter.default.addObserver(
            forName: CoreDataStorage.didReceiveRemoteChanges, object: nil, queue: nil
        ) { [weak self] _ in self?.scheduleSnapshot() }
        observers.append(remoteObserver)

        // iOS purge 직전 debounce 우회하여 즉시 flush → purge 후 마지막 정상 상태 보존
        let willResetObserver = NotificationCenter.default.addObserver(
            forName: CoreDataStorage.SyncResetNotification.willReset, object: nil, queue: nil
        ) { [weak self] _ in
            self?.handleSyncResetImminent()
        }
        observers.append(willResetObserver)

        queue.async { [weak self] in
            self?.writeSnapshotNow()
        }
    }

    func stopObserving() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        _pendingWorkItem.withLock { item in
            item?.cancel()
            item = nil
        }
    }

    private func scheduleSnapshot() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.writeSnapshotNow()
        }
        _pendingWorkItem.withLock { item in
            item?.cancel()
            item = workItem
        }
        queue.asyncAfter(deadline: .now() + Self.debounceSeconds, execute: workItem)
    }

    /// 강제 저장 — 앱 종료 직전/sync-reset 직전 등에서 flushing 용도.
    /// debounce 중인 쓰기와 파일 I/O가 겹치지 않도록 queue에서 동기 실행한다.
    func flushNow() {
        cancelPendingSnapshot()
        queue.sync { [weak self] in
            self?.writeSnapshotNow()
        }
    }

    /// iOS purge 직전(willReset): 현재 상태를 flush한 뒤 reset hold를 설정한다.
    /// 알림을 보낸 스레드에서 동기로 끝나야 purge 전에 파일이 기록된다.
    private func handleSyncResetImminent() {
        os_log(.error, log: .default, "🛟 SafetySnapshot: sync-reset imminent — flushing immediately")
        cancelPendingSnapshot()
        queue.sync { [weak self] in
            self?.writeSnapshotNow()
            self?.establishResetHold()
        }
    }

    private func cancelPendingSnapshot() {
        _pendingWorkItem.withLock { item in
            item?.cancel()
            item = nil
        }
    }

    private func writeSnapshotNow() {
        let context = container.newBackgroundContext()
        do {
            // hold는 dump 이전에 읽는다 — dump 도중 restore()가 hold를 해제해도 부분 상태로 덮어쓰지 않도록.
            // 보존할 백업 파일 자체가 없으면 hold는 의미가 없으므로 현재 상태를 기록한다.
            let heldChildCount = snapshotExists ? resetHoldChildCount : nil
            let snapshot = try UserCollectionSnapshot.dump(from: context)
            if let heldChildCount, snapshot.totalChildCount < heldChildCount {
                // sync reset 후 아직(또는 영영) 회복되지 않은 부분 상태 — reset 이전 백업을 덮어쓰지 않는다.
                os_log(.error, log: .default,
                       "🛟 SafetySnapshot skipped: %d children < pre-reset backup %d (holding)",
                       snapshot.totalChildCount, heldChildCount)
                return
            }
            let data = try snapshot.toData()
            // CloudKit can deliver background imports while the device is locked. The snapshot must
            // remain writable after the first unlock so a sync-reset flush can preserve recent data.
            try data.write(to: snapshotURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            try fileAttributeSetter(snapshotURL, [.protectionKey: Self.snapshotFileProtection])
            applySnapshotResourceValues()
            updateMetadataCache(createdAt: snapshot.createdAt, childCount: snapshot.totalChildCount)
            if resetHoldChildCount != nil {
                // 현재 데이터가 reset 이전 수준 이상으로 회복됐거나 보존할 파일이 없었음 — 보존 해제
                releaseResetHold()
            }
            os_log(.info, log: .default,
                   "🛟 SafetySnapshot written: %d children, %d bytes",
                   snapshot.totalChildCount, data.count)
        } catch SafetySnapshotError.noUserCollection {
            // UC 없음 = 아직 아무 것도 없는 상태. 기존 스냅샷은 건드리지 않음 (유실된 상태에서 덮어쓰지 않기 위해)
            os_log(.info, log: .default, "🛟 SafetySnapshot skipped: no UC in current store")
        } catch {
            os_log(.error, log: .default,
                   "🛟 SafetySnapshot write failed: %{public}@",
                   error.localizedDescription)
        }
    }

    private func applySnapshotResourceValues() {
        var url = snapshotURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch {
            // 백업 제외(isExcludedFromBackup) 회귀를 Crashlytics에서 관측할 수 있도록 비치명 에러로 보고한다.
            // 파일 보호 등급은 write 옵션 + setAttributes로 이미 적용되므로 암호화 경계 자체는 유지된다.
            Log.error(
                name: "SafetySnapshotBackupExclusion",
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Restore

    enum RestoreOutcome {
        case success(totalRestored: Int)
        case noSnapshot
        case failed(Error)
    }

    /// 사용자 확인 후 호출. 기존 UC + 자식을 모두 삭제하고 스냅샷으로 재구성.
    /// **파괴적 동작** — 호출 전 사용자 명시적 동의 필요.
    func restore(completion: @escaping (RestoreOutcome) -> Void) {
        container.performBackgroundTask { [weak self] context in
            guard let self else {
                return
            }
            let outcome: RestoreOutcome
            do {
                let data = try Data(contentsOf: self.snapshotURL)
                let snapshot = try UserCollectionSnapshot.from(data: data)
                try Self.wipeExistingCollection(in: context)
                #if DEBUG
                try self.beforeApplyingSnapshotForTesting?(context)
                #endif
                try snapshot.apply(to: context)
                try context.save()
                // 사용자가 reset 이전 백업으로 되돌렸으므로 보존 목적 달성 — 이후 스냅샷은 복원된 상태를 기준으로 갱신
                self.releaseResetHold()
                os_log(.error, log: .default,
                       "🛟 SafetySnapshot RESTORED: %d children",
                       snapshot.totalChildCount)
                outcome = .success(totalRestored: snapshot.totalChildCount)
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
                outcome = .noSnapshot
            } catch {
                context.rollback()
                os_log(.error, log: .default,
                       "🛟 SafetySnapshot restore FAILED: %{public}@",
                       error.localizedDescription)
                outcome = .failed(error)
            }
            DispatchQueue.main.async { completion(outcome) }
        }
    }

    private static func wipeExistingCollection(in context: NSManagedObjectContext) throws {
        let entityNames = [
            "ItemEntity", "DailyTaskEntity", "VillagersLikeEntity",
            "VillagersHouseEntity", "NPCLikeEntity", "VariantCollectionEntity",
            "UserCollectionEntity"
        ]
        for name in entityNames {
            let request = NSFetchRequest<NSManagedObject>(entityName: name)
            request.includesPropertyValues = false
            let objects = try context.fetch(request)
            objects.forEach(context.delete)
        }
    }

    // MARK: - Sync Reset Hold
    //
    // sync reset(로컬 store purge → CloudKit re-import) 뒤에는 re-import가 일부만 도착한 상태가
    // "정상 import 완료"처럼 보일 수 있다. 그 상태로 debounce 스냅샷이 기존 백업을 덮어쓰면 마지막 안전망이 사라진다.
    // 그래서 willReset 직전 flush 시점의 항목 수를 hold로 기록하고, 현재 데이터가 그 수 이상으로 회복되거나
    // 사용자가 명시적으로 결정(로컬 복원 / 현재 데이터 유지 / 데이터 초기화)할 때까지 더 적은 항목의
    // 스냅샷으로 덮어쓰지 않는다. purge 직후 재실행되는 경우가 많으므로 UserDefaults에 영속화한다.

    private static let resetHoldChildCountKey = "SafetySnapshot_resetHoldChildCount"

    /// sync reset 이전 백업을 보존 중이면 그 백업의 항목 수, 아니면 nil
    var resetHoldChildCount: Int? {
        guard userDefaults.object(forKey: Self.resetHoldChildCountKey) != nil else {
            return nil
        }
        return userDefaults.integer(forKey: Self.resetHoldChildCountKey)
    }

    /// 사용자가 현재 데이터를 기준으로 삼기로 명시적으로 결정했을 때(현재 데이터 유지, 데이터 초기화) 호출.
    /// 이후 스냅샷은 다시 현재 상태로 갱신된다.
    func releaseResetHold() {
        guard resetHoldChildCount != nil else {
            return
        }
        userDefaults.removeObject(forKey: Self.resetHoldChildCountKey)
        os_log(.info, log: .default, "🛟 SafetySnapshot reset hold released")
    }

    /// willReset 직전 flush 이후 호출. 이미 hold 중이면 더 큰 값을 유지한다
    /// (부분 상태에서 reset이 연속으로 일어나도 원래 백업 기준을 잃지 않기 위해).
    private func establishResetHold() {
        guard let metadata = readMetadata(), metadata.totalChildCount > 0 else {
            return
        }
        let heldChildCount = max(resetHoldChildCount ?? 0, metadata.totalChildCount)
        userDefaults.set(heldChildCount, forKey: Self.resetHoldChildCountKey)
        os_log(.error, log: .default, "🛟 SafetySnapshot reset hold established: %d children", heldChildCount)
    }

    /// sync reset 이후 현재 데이터가 보존 중인 백업보다 적으면 현재 항목 수를, 아니면 nil을 반환한다.
    /// non-nil이면 사용자에게 로컬 백업 복원을 제안할 상황이다.
    func currentChildCountIfBelowResetHold() -> Int? {
        guard let heldChildCount = resetHoldChildCount, snapshotExists else {
            return nil
        }
        let current = currentChildCount()
        return current < heldChildCount ? current : nil
    }

    /// 현재 store의 항목 수 — 스냅샷 `totalChildCount`와 같은 기준(관계가 가장 많은 UC의 자식 수).
    func currentChildCount() -> Int {
        let context = container.newBackgroundContext()
        var count = 0
        context.performAndWait {
            let request: NSFetchRequest<UserCollectionEntity> = UserCollectionEntity.fetchRequest()
            let collections = (try? context.fetch(request)) ?? []
            count = collections.map { UserCollectionSnapshot.relationshipCount(of: $0) }.max() ?? 0
        }
        return count
    }

    // MARK: - Metadata for UI

    struct Metadata {
        let createdAt: Date
        let totalChildCount: Int
    }

    /// UI에서 "N분 전에 저장된 백업이 있습니다 (아이템 N개)"를 표시하기 위한 요약.
    /// UserDefaults 캐시 우선, 없으면 파일을 unarchive하여 역으로 캐시 채움.
    func readMetadata() -> Metadata? {
        if let cached = readCachedMetadata() {
            return cached
        }
        return readMetadataFromFile()
    }

    private func readCachedMetadata() -> Metadata? {
        guard let createdAt = userDefaults.object(forKey: Self.metadataCreatedAtKey) as? Date else {
            return nil
        }
        let count = userDefaults.integer(forKey: Self.metadataChildCountKey)
        // 파일이 외부에서 삭제된 경우 캐시가 stale할 수 있으므로 실제 파일 존재 여부 확인
        guard snapshotExists else {
            clearMetadataCache()
            return nil
        }
        return Metadata(createdAt: createdAt, totalChildCount: count)
    }

    private func readMetadataFromFile() -> Metadata? {
        guard snapshotExists else {
            return nil
        }
        do {
            let data = try Data(contentsOf: snapshotURL)
            let snapshot = try UserCollectionSnapshot.from(data: data)
            updateMetadataCache(createdAt: snapshot.createdAt, childCount: snapshot.totalChildCount)
            return Metadata(createdAt: snapshot.createdAt, totalChildCount: snapshot.totalChildCount)
        } catch {
            os_log(.error, log: .default,
                   "🛟 SafetySnapshot metadata read failed: %{public}@",
                   error.localizedDescription)
            return nil
        }
    }

    private func updateMetadataCache(createdAt: Date, childCount: Int) {
        userDefaults.set(createdAt, forKey: Self.metadataCreatedAtKey)
        userDefaults.set(childCount, forKey: Self.metadataChildCountKey)
    }

    private func clearMetadataCache() {
        userDefaults.removeObject(forKey: Self.metadataCreatedAtKey)
        userDefaults.removeObject(forKey: Self.metadataChildCountKey)
    }

    #if DEBUG
    /// 테스트 전용 — willReset 알림 수신과 동일한 경로(flush + reset hold)를 실행한다.
    func simulateSyncResetImminentForTesting() {
        handleSyncResetImminent()
    }
    #endif

    /// 복원 완료 후 또는 사용자가 의도적으로 지울 때.
    func deleteSnapshot() {
        try? FileManager.default.removeItem(at: snapshotURL)
        clearMetadataCache()
    }
}
