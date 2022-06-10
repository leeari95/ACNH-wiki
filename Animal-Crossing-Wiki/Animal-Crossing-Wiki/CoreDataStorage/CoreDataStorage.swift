//
//  CoreDataStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/09.
//

import Foundation
import CoreData

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
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension CoreDataStorage {
    func insert(entityName: String, items: [String: Any]) {
        let context = persistentContainer.viewContext
        let managedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        update(entityName: entityName, managedObject: managedObject, items: items)
    }
    
    @discardableResult
    func fetch(
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> [NSManagedObject]? {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        guard let newData = try? context.fetch(request) else {
            return nil
        }
        return newData
    }
    
    func update(entityName: String, managedObject: NSManagedObject, items: [String: Any]) {
        let keys = managedObject.entity.attributesByName.keys
        for key in keys {
            if let value = items[key] {
                managedObject.setValue(value, forKey: key)
            }
        }
        saveContext()
        fetch(entityName: entityName)
    }
    
    func delete(_ managedObject: NSManagedObject) {
        let context = persistentContainer.viewContext
        context.delete(managedObject)
        saveContext()
    }
}
