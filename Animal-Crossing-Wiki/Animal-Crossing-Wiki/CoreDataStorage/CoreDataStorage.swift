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
    private init() {}

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
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
