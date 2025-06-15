//
//  CoreDataItemsStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

final class CoreDataItemsStorage: ItemsStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    private func updateItemInCoreData(
        _ item: Item,
        operation: @escaping (inout Item) -> Void,
        shouldAddToCollection: ((Item) -> Bool)? = nil
    ) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                
                if let existingItem = items.first(where: { $0.name == item.name && $0.genuine == item.genuine }) {
                    object.removeFromCritters(existingItem)
                }
                
                var updatedItem = item
                operation(&updatedItem)
                
                let shouldAdd = shouldAddToCollection?(updatedItem) ?? true
                if shouldAdd {
                    let newItem = ItemEntity(updatedItem, context: context)
                    object.addToCritters(newItem)
                }
                
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }

    func fetch() -> Single<[Item]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let itemEntities = object.critters?.allObjects as? [ItemEntity] ?? []
                    let critters = try itemEntities.map { try $0.toDomain() }
                    single(.success(critters))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func update(_ item: Item) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                if let index = items.firstIndex(where: { $0.name == item.name && $0.genuine == item.genuine }) {
                    object.removeFromCritters(items[index])
                } else {
                    let newItem = ItemEntity(item, context: context)
                    object.addToCritters(newItem)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }

    func updates(_ items: [Item]) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let newItems = items.map { ItemEntity($0, context: context) }
                object.addToCritters(NSSet(array: newItems))
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }

    func reset(category: Category) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                object.removeFromCritters(NSSet(array: items.filter { $0.category == category.rawValue }))
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func updateVariantCheck(itemName: String, variantId: String, isChecked: Bool) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                
                if let existingItem = items.first(where: { $0.name == itemName }) {
                    var item = try existingItem.toDomain()
                    var checkedVariants = item.checkedVariants ?? Set<String>()
                    
                    if isChecked {
                        checkedVariants.insert(variantId)
                    } else {
                        checkedVariants.remove(variantId)
                    }
                    
                    item.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
                    
                    object.removeFromCritters(existingItem)
                    
                    if let checkedVariants = item.checkedVariants, !checkedVariants.isEmpty {
                        let newItem = ItemEntity(item, context: context)
                        object.addToCritters(newItem)
                    }
                } else if isChecked {
                }
                
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func updateVariantCheck(item: Item, variantId: String, isChecked: Bool) {
        updateItemInCoreData(item) { updatedItem in
            var checkedVariants = updatedItem.checkedVariants ?? Set<String>()
            
            if isChecked {
                checkedVariants.insert(variantId)
            } else {
                checkedVariants.remove(variantId)
            }
            
            updatedItem.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
        } shouldAddToCollection: { updatedItem in
            return updatedItem.checkedVariants?.isEmpty == false
        }
    }
    
    func updateVariantCheckAndAcquire(item: Item, variantId: String, isChecked: Bool, shouldAcquire: Bool) {
        updateItemInCoreData(item) { updatedItem in
            var checkedVariants = updatedItem.checkedVariants ?? Set<String>()
            
            if isChecked {
                checkedVariants.insert(variantId)
            } else {
                checkedVariants.remove(variantId)
            }
            
            updatedItem.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
        } shouldAddToCollection: { updatedItem in
            let hasCheckedVariants = updatedItem.checkedVariants?.isEmpty == false
            return shouldAcquire || hasCheckedVariants
        }
        
        if shouldAcquire {
            DispatchQueue.main.async {
                Items.shared.updateItem(item)
            }
        }
    }
    
    func clearVariantsAndUpdate(_ item: Item) {
        updateItemInCoreData(item) { updatedItem in
            updatedItem.checkedVariants = nil
        } shouldAddToCollection: { _ in
            return false
        }
    }
}
