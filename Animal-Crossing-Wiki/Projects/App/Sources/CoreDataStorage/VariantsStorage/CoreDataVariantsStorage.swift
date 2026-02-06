//
//  CoreDataVariantsStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude Code on 2026/02/01.
//

import Foundation
import RxSwift

final class CoreDataVariantsStorage: VariantsStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetch() -> Single<Set<String>> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let variantEntities = object.variants?.allObjects as? [VariantCollectionEntity] ?? []
                    let variantIds = Set(variantEntities.compactMap { $0.variantId })
                    single(.success(variantIds))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func fetchByItem(_ itemName: String) -> Single<Set<String>> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let variantEntities = object.variants?.allObjects as? [VariantCollectionEntity] ?? []
                    let variantIds = Set(variantEntities
                        .filter { $0.itemName == itemName }
                        .compactMap { $0.variantId })
                    single(.success(variantIds))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func fetchAll() -> Single<[String: Set<String>]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let variantEntities = object.variants?.allObjects as? [VariantCollectionEntity] ?? []

                    var variantsByItem: [String: Set<String>] = [:]
                    for entity in variantEntities {
                        guard let itemName = entity.itemName, let variantId = entity.variantId else { continue }
                        variantsByItem[itemName, default: []].insert(variantId)
                    }

                    single(.success(variantsByItem))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func add(_ variantId: String, itemName: String) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let variants = object.variants?.allObjects as? [VariantCollectionEntity] ?? []

                if variants.contains(where: { $0.variantId == variantId }) {
                    return
                }

                let newVariant = VariantCollectionEntity(context: context)
                newVariant.variantId = variantId
                newVariant.itemName = itemName
                object.addToVariants(newVariant)

                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }

    func remove(_ variantId: String) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let variants = object.variants?.allObjects as? [VariantCollectionEntity] ?? []

                if let variant = variants.first(where: { $0.variantId == variantId }) {
                    object.removeFromVariants(variant)
                    context.delete(variant)
                    context.saveContext()
                }
            } catch {
                debugPrint(error)
            }
        }
    }

    func removeAll(for itemName: String) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let allVariants = object.variants?.allObjects as? [VariantCollectionEntity] ?? []
                let variantsToRemove = allVariants.filter { $0.itemName == itemName }

                variantsToRemove.forEach { variant in
                    object.removeFromVariants(variant)
                    context.delete(variant)
                }

                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
