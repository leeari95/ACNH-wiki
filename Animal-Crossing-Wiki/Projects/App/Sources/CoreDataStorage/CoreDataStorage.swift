//
//  CoreDataStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/09.
//

import Foundation
import CoreData
import CloudKit

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
    private init() {}

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage")
        
        // CloudKit 설정
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to get persistentStoreDescription")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                print("⚠️ CoreData store loading error: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - iCloud Sync
    
    func checkiCloudAccountStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.handleiCloudAccountStatus(status, error: error)
            }
        }
    }
    
    private func handleiCloudAccountStatus(_ status: CKAccountStatus, error: Error?) {
        switch status {
        case .available:
            print("✅ iCloud account available")
            setupRemoteChangeNotifications()
        case .noAccount:
            print("⚠️ No iCloud account")
            NotificationCenter.default.post(name: .iCloudAccountUnavailable, object: nil)
        case .restricted:
            print("⚠️ iCloud account restricted")
            NotificationCenter.default.post(name: .iCloudAccountRestricted, object: nil)
        case .couldNotDetermine:
            print("⚠️ Could not determine iCloud account status")
        case .temporarilyUnavailable:
            print("⚠️ iCloud temporarily unavailable")
        @unknown default:
            print("⚠️ Unknown iCloud account status")
        }
        
        if let error = error {
            print("❌ iCloud account check error: \(error)")
        }
    }
    
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        print("📱 Received remote store change notification")
        NotificationCenter.default.post(name: .dataDidSyncFromCloud, object: nil)
    }
}

extension CoreDataStorage {

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

// MARK: - Notification Names
extension Notification.Name {
    static let iCloudAccountUnavailable = Notification.Name("iCloudAccountUnavailable")
    static let iCloudAccountRestricted = Notification.Name("iCloudAccountRestricted")
    static let dataDidSyncFromCloud = Notification.Name("dataDidSyncFromCloud")
}
