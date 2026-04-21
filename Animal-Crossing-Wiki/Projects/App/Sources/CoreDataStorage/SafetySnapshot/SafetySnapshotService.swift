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
    private var contextObserver: NSObjectProtocol?

    /// 앱 시작 시 1회 호출 — LocalStore(또는 현 persistent container)의 save 알림을 관찰.
    func startObserving(container: NSPersistentContainer) {
        stopObserving()
        contextObserver = NotificationCenter.default.addObserver(
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
    }

    func stopObserving() {
        if let observer = contextObserver {
            NotificationCenter.default.removeObserver(observer)
            contextObserver = nil
        }
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
