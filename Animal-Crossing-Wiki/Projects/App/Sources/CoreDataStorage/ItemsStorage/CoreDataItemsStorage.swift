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
                    // 기존 아이템이 있는 경우, 변형 체크 상태 업데이트
                    var item = try existingItem.toDomain()
                    var checkedVariants = item.checkedVariants ?? Set<String>()
                    
                    if isChecked {
                        checkedVariants.insert(variantId)
                    } else {
                        checkedVariants.remove(variantId)
                    }
                    
                    item.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
                    
                    // 기존 아이템 제거 후 새 아이템 추가
                    object.removeFromCritters(existingItem)
                    
                    // 변형이 하나라도 체크되어 있으면 아이템을 컬렉션에 유지
                    if let checkedVariants = item.checkedVariants, !checkedVariants.isEmpty {
                        let newItem = ItemEntity(item, context: context)
                        object.addToCritters(newItem)
                    }
                } else if isChecked {
                    // 새로운 아이템인 경우, 변형 체크와 함께 추가
                    // 주의: 여기서는 전체 아이템 정보가 필요하므로, 상위에서 전체 Item 객체를 전달받아야 함
                    // 현재는 단순히 variantId만 저장
                }
                
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func updateVariantCheck(item: Item, variantId: String, isChecked: Bool) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                
                // 기존 아이템 제거
                if let existingItem = items.first(where: { $0.name == item.name && $0.genuine == item.genuine }) {
                    object.removeFromCritters(existingItem)
                }
                
                // 변형 체크 상태 업데이트
                var updatedItem = item
                var checkedVariants = updatedItem.checkedVariants ?? Set<String>()
                
                if isChecked {
                    checkedVariants.insert(variantId)
                } else {
                    checkedVariants.remove(variantId)
                }
                
                updatedItem.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
                
                // 변형이 하나라도 체크되어 있으면 아이템을 컬렉션에 추가
                if let checkedVariants = updatedItem.checkedVariants, !checkedVariants.isEmpty {
                    let newItem = ItemEntity(updatedItem, context: context)
                    object.addToCritters(newItem)
                }
                
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func updateVariantCheckAndAcquire(item: Item, variantId: String, isChecked: Bool, shouldAcquire: Bool) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                
                // 기존 아이템 제거
                if let existingItem = items.first(where: { $0.name == item.name && $0.genuine == item.genuine }) {
                    object.removeFromCritters(existingItem)
                }
                
                // 변형 체크 상태 업데이트
                var updatedItem = item
                var checkedVariants = updatedItem.checkedVariants ?? Set<String>()
                
                if isChecked {
                    checkedVariants.insert(variantId)
                } else {
                    checkedVariants.remove(variantId)
                }
                
                updatedItem.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
                let hasCheckedVariants = updatedItem.checkedVariants != nil && !updatedItem.checkedVariants!.isEmpty
                if shouldAcquire || hasCheckedVariants {
                    let newItem = ItemEntity(updatedItem, context: context)
                    object.addToCritters(newItem)
                    
                    if shouldAcquire {
                        // Items.shared도 업데이트
                        DispatchQueue.main.async {
                            Items.shared.updateItem(item)
                        }
                    }
                }
                
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
