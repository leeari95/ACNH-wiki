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
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(Self.fileName)
    }

    var snapshotExists: Bool {
        FileManager.default.fileExists(atPath: snapshotURL.path)
    }

    // MARK: - Debounced Save

    /// 연속된 CoreData 저장을 합치기 위한 지연 시간.
    /// 너무 짧으면 매 수집마다 디스크 I/O, 너무 길면 최근 변경이 스냅샷에 없을 위험.
    private static let debounceSeconds: TimeInterval = 30

    private let queue = DispatchQueue(label: "app.safety.snapshot", qos: .utility)
    private var pendingWorkItem: DispatchWorkItem?
    private var observers: [NSObjectProtocol] = []

    /// 앱 시작 시 1회 호출 — 다음 이벤트에 대해 모두 스냅샷 작성을 예약:
    /// 1. 로컬 context save (사용자 편집)
    /// 2. CloudKit Import 완료 (원격 기기의 변경을 수신)
    /// 3. 원격 persistent store 변경 알림
    /// 또한 즉시 **initial snapshot**을 비동기로 작성하여, 이번 세션 중 아무 편집이 없더라도
    /// 최신 상태의 백업이 Documents/에 존재하도록 보장한다.
    func startObserving(container: NSPersistentContainer) {
        stopObserving()

        // (1) 로컬 save 관찰 — 사용자 편집 경로
        let saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            // 다른 container의 save가 섞이면 무시
            guard let ctx = notification.object as? NSManagedObjectContext,
                  ctx.persistentStoreCoordinator === container.persistentStoreCoordinator else {
                return
            }
            self.scheduleSnapshot(container: container)
        }
        observers.append(saveObserver)

        // (2) CloudKit Import 완료 알림 — import로 들어온 데이터도 스냅샷에 반영
        let importObserver = NotificationCenter.default.addObserver(
            forName: CoreDataStorage.didFinishCloudImport,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.scheduleSnapshot(container: container)
        }
        observers.append(importObserver)

        // (3) 원격 store 변경 알림 — 동기화로 인한 머지가 일어난 직후
        let remoteObserver = NotificationCenter.default.addObserver(
            forName: CoreDataStorage.didReceiveRemoteChanges,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.scheduleSnapshot(container: container)
        }
        observers.append(remoteObserver)

        // (4) Initial snapshot — 현재 store에 이미 데이터가 있으면 즉시 백업
        // 디스크 I/O를 줄이기 위해 background queue에서 debounce 없이 한 번 실행
        queue.async { [weak self] in
            self?.writeSnapshotNow(container: container)
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

    private func scheduleSnapshot(container: NSPersistentContainer) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.writeSnapshotNow(container: container)
        }
        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + Self.debounceSeconds, execute: workItem)
    }

    /// 강제 저장 — 앱 종료 직전 등에서 flushing 용도. 실패해도 무시.
    func flushNow(container: NSPersistentContainer) {
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
        writeSnapshotNow(container: container)
    }

    private func writeSnapshotNow(container: NSPersistentContainer) {
        let context = container.newBackgroundContext()
        do {
            let snapshot = try UserCollectionSnapshot.dump(from: context)
            let data = try snapshot.toData()
            try atomicWrite(data: data, to: snapshotURL)
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

    private func atomicWrite(data: Data, to url: URL) throws {
        // .atomic → 임시 파일 경유 rename. 중간 종료 시에도 기존 파일 보존됨.
        try data.write(to: url, options: [.atomic])
    }

    // MARK: - Restore

    enum RestoreOutcome {
        case success(totalRestored: Int)
        case noSnapshot
        case failed(Error)
    }

    /// 사용자 확인 후 호출. 대상 container의 기존 UC + 자식을 모두 삭제하고 스냅샷으로 재구성.
    /// **파괴적 동작** — 호출 전 기존 데이터가 이미 비어있거나, 사용자 명시적 동의 필요.
    func restore(to container: NSPersistentContainer, completion: @escaping (RestoreOutcome) -> Void) {
        guard snapshotExists else {
            DispatchQueue.main.async { completion(.noSnapshot) }
            return
        }

        container.performBackgroundTask { context in
            let outcome: RestoreOutcome
            do {
                let data = try Data(contentsOf: self.snapshotURL)
                let snapshot = try UserCollectionSnapshot.from(data: data)

                // 기존 UC + 자식을 모두 삭제 (cascade rule이 설정되어 있지 않은 relationship이 있을 수 있으므로 안전하게 명시 삭제)
                try Self.wipeExistingCollection(in: context)

                try snapshot.apply(to: context)
                try context.save()

                os_log(.error, log: .default,
                       "🛟 SafetySnapshot RESTORED: %d children",
                       snapshot.totalChildCount)
                outcome = .success(totalRestored: snapshot.totalChildCount)
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
        let fileSize: Int64
    }

    /// UI에서 "N분 전에 저장된 백업이 있습니다 (아이템 N개)"를 표시하기 위한 요약.
    /// 실제 복원은 restore(...)를 호출해야 한다.
    func readMetadata() -> Metadata? {
        guard snapshotExists else { return nil }
        do {
            let data = try Data(contentsOf: snapshotURL)
            let snapshot = try UserCollectionSnapshot.from(data: data)
            let size = (try? snapshotURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
            return Metadata(
                createdAt: snapshot.createdAt,
                totalChildCount: snapshot.totalChildCount,
                fileSize: size
            )
        } catch {
            os_log(.error, log: .default,
                   "🛟 SafetySnapshot metadata read failed: %{public}@",
                   error.localizedDescription)
            return nil
        }
    }

    /// 복원 완료 후 또는 사용자가 의도적으로 지울 때.
    func deleteSnapshot() {
        try? FileManager.default.removeItem(at: snapshotURL)
    }
}
