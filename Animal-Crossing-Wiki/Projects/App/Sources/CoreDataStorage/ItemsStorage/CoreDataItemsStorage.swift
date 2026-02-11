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
                let existingItems = object.critters?.allObjects as? [ItemEntity] ?? []
                
                for item in items {
                    // 중복 체크: 이름과 genuine 값으로 기존 항목 확인
                    let isDuplicate = existingItems.contains { existing in
                        existing.name == item.name && existing.genuine == item.genuine
                    }
                    
                    // 중복이 아닌 경우에만 추가
                    if !isDuplicate {
                        let newItem = ItemEntity(item, context: context)
                        object.addToCritters(newItem)
                    }
                }
                
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
    
    func updateVariantCollection(_ item: Item, variantName: String, isCollected: Bool) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let items = object.critters?.allObjects as? [ItemEntity] ?? []
                
                // 기존 아이템을 찾아서 variant 상태를 업데이트
                if let index = items.firstIndex(where: { $0.name == item.name && $0.genuine == item.genuine }) {
                    var variants = items[index].variations
//                    variants?[variantName] = isCollected
//                    items[index].variants = variants
                } else {
                    // 새로운 아이템 추가
                    let newItem = ItemEntity(item, context: context)
                    newItem.variants = [variantName: isCollected]
                    object.addToCritters(newItem)
                }
                
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
