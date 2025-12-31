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
    private init() {
        setupRemoteChangeNotification()
    }

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage")

        // CloudKit 컨테이너 옵션 설정
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // iCloud 동기화를 위한 CloudKit 컨테이너 식별자 설정
        // 실제 CloudKit 컨테이너 ID는 프로젝트 설정에 맞게 조정 필요
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.leeari95.ACNHWiki"
        )

        // 원격 변경사항 알림 활성화
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // 히스토리 추적 활성화 (동기화에 필요)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        // 자동 병합 정책 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    // MARK: - Remote Change Notification

    private func setupRemoteChangeNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        // 원격 변경사항이 발생했을 때 UI 갱신을 위한 알림 전송
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didReceiveRemoteChanges, object: nil)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didReceiveRemoteChanges = Notification.Name("didReceiveRemoteChanges")
}

// MARK: - Background Task & User Collection

extension CoreDataStorage {

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    func getUserCollection(_ context: NSManagedObjectContext) throws -> UserCollectionEntity {
        let request = UserCollectionEntity.fetchRequest()
        return try context.fetch(request).first ?? UserCollectionEntity(UserInfo(), context: context)
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
