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

    var snapshotURL: URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents directory unavailable")
        }
        return documents.appendingPathComponent(Self.fileName)
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
    private var pendingWorkItem: DispatchWorkItem?
    private var observers: [NSObjectProtocol] = []

    private var container: NSPersistentContainer {
        CoreDataStorage.shared.persistentContainer
    }

    /// 앱 시작 시 1회 호출 — 다음 이벤트에 대해 모두 스냅샷 작성을 예약:
    /// 1. 로컬 context save (사용자 편집)
    /// 2. CloudKit Import 완료 (원격 기기의 변경을 수신)
    /// 3. 원격 persistent store 변경 알림
    /// 4. CloudKit Sync Reset 임박 (iOS가 로컬 purge 직전에 마지막 flush)
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
            os_log(.error, log: .default, "🛟 SafetySnapshot: sync-reset imminent — flushing immediately")
            self?.flushNow()
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
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }

    private func scheduleSnapshot() {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.writeSnapshotNow()
        }
        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + Self.debounceSeconds, execute: workItem)
    }

    /// 강제 저장 — 앱 종료 직전/sync-reset 직전 등에서 flushing 용도.
    func flushNow() {
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
        writeSnapshotNow()
    }

    private func writeSnapshotNow() {
        let context = container.newBackgroundContext()
        do {
            let snapshot = try UserCollectionSnapshot.dump(from: context)
            let data = try snapshot.toData()
            try data.write(to: snapshotURL, options: [.atomic])
            updateMetadataCache(createdAt: snapshot.createdAt, childCount: snapshot.totalChildCount)
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
            guard let self else { return }
            let outcome: RestoreOutcome
            do {
                let data = try Data(contentsOf: self.snapshotURL)
                let snapshot = try UserCollectionSnapshot.from(data: data)
                try Self.wipeExistingCollection(in: context)
                try snapshot.apply(to: context)
                try context.save()
                os_log(.error, log: .default,
                       "🛟 SafetySnapshot RESTORED: %d children",
                       snapshot.totalChildCount)
                outcome = .success(totalRestored: snapshot.totalChildCount)
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
                outcome = .noSnapshot
            } catch {
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
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: request)
            delete.resultType = .resultTypeObjectIDs
            if let result = try context.execute(delete) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
        }
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
        guard let createdAt = UserDefaults.standard.object(forKey: Self.metadataCreatedAtKey) as? Date else {
            return nil
        }
        let count = UserDefaults.standard.integer(forKey: Self.metadataChildCountKey)
        // 파일이 외부에서 삭제된 경우 캐시가 stale할 수 있으므로 실제 파일 존재 여부 확인
        guard snapshotExists else {
            clearMetadataCache()
            return nil
        }
        return Metadata(createdAt: createdAt, totalChildCount: count)
    }

    private func readMetadataFromFile() -> Metadata? {
        guard snapshotExists else { return nil }
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
        UserDefaults.standard.set(createdAt, forKey: Self.metadataCreatedAtKey)
        UserDefaults.standard.set(childCount, forKey: Self.metadataChildCountKey)
    }

    private func clearMetadataCache() {
        UserDefaults.standard.removeObject(forKey: Self.metadataCreatedAtKey)
        UserDefaults.standard.removeObject(forKey: Self.metadataChildCountKey)
    }

    /// 복원 완료 후 또는 사용자가 의도적으로 지울 때.
    func deleteSnapshot() {
        try? FileManager.default.removeItem(at: snapshotURL)
        clearMetadataCache()
    }
}
