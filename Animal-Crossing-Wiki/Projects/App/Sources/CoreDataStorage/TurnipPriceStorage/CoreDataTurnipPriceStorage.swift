//
//  CoreDataTurnipPriceStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift
import CoreData

final class CoreDataTurnipPriceStorage: TurnipPriceStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetchCurrentWeekPrice() -> Single<TurnipPrice?> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let priceEntities = object.turnipPrices?.allObjects as? [TurnipPriceEntity] ?? []
                    let currentWeekStart = Date().startOfWeek

                    let currentWeekPrice = priceEntities.first { entity in
                        guard let weekStart = entity.weekStartDate else { return false }
                        return Calendar.current.isDate(weekStart, inSameDayAs: currentWeekStart)
                    }

                    single(.success(currentWeekPrice?.toDomain()))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func fetchAllPrices() -> Single<[TurnipPrice]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let priceEntities = object.turnipPrices?.allObjects as? [TurnipPriceEntity] ?? []
                    let prices = priceEntities
                        .map { $0.toDomain() }
                        .sorted { $0.weekStartDate > $1.weekStartDate }
                    single(.success(prices))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func savePrice(_ turnipPrice: TurnipPrice) -> Single<TurnipPrice> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let newPriceEntity = TurnipPriceEntity(turnipPrice, context: context)
                    object.addToTurnipPrices(newPriceEntity)
                    context.saveContext()
                    single(.success(newPriceEntity.toDomain()))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func updatePrice(_ turnipPrice: TurnipPrice) {
        coreDataStorage.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let priceEntities = object.turnipPrices?.allObjects as? [TurnipPriceEntity] ?? []

                if let existingEntity = priceEntities.first(where: { $0.id == turnipPrice.id }) {
                    existingEntity.buyPrice = Int64(turnipPrice.buyPrice ?? 0)
                    existingEntity.prices = turnipPrice.prices.map { NSNumber(value: $0 ?? -1) } as NSArray
                    existingEntity.weekStartDate = turnipPrice.weekStartDate
                } else {
                    let newEntity = TurnipPriceEntity(turnipPrice, context: context)
                    object.addToTurnipPrices(newEntity)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }

    func deletePrice(_ turnipPrice: TurnipPrice) -> Single<TurnipPrice> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let priceEntities = object.turnipPrices?.allObjects as? [TurnipPriceEntity] ?? []

                    guard let entityToDelete = priceEntities.first(where: { $0.id == turnipPrice.id }) else {
                        single(.failure(CoreDataStorageError.notFound))
                        return
                    }

                    object.removeFromTurnipPrices(entityToDelete)
                    context.saveContext()
                    single(.success(entityToDelete.toDomain()))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }
}
