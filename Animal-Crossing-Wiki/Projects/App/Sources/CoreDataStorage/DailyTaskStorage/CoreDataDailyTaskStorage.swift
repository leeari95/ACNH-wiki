//
//  CoreDataDailyTaskStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift
import CoreData

final class CoreDataDailyTaskStorage: DailyTaskStorage, ErrorHandling {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetchTasks() -> Single<[DailyTask]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    var itemEntities = object.dailyTasks?.allObjects as? [DailyTaskEntity] ?? []
                    if itemEntities.isEmpty {
                        itemEntities = DailyTask.tasks.map { DailyTaskEntity($0, context: context)}
                        object.addToDailyTasks(NSSet(array: itemEntities))
                        context.saveContext()
                    }
                    let tasks = itemEntities.map { $0.toDomain() }.sorted(by: { $0.createdDate < $1.createdDate })
                    single(.success(tasks))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func insertTask(_ task: DailyTask) -> Single<DailyTask> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let newTask = DailyTaskEntity(task, context: context)
                    object.addToDailyTasks(newTask)
                    context.saveContext()
                    single(.success(newTask.toDomain()))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }

    }

    func updateTask(_ task: DailyTask) {
        self.coreDataStorage.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let itemEntities = object.dailyTasks?.allObjects as? [DailyTaskEntity] ?? []
                if let index = itemEntities.firstIndex(where: { $0.id == task.id }) {
                    itemEntities[index].name = task.name
                    itemEntities[index].icon = task.icon
                    itemEntities[index].progressList = task.progressList as NSArray
                    itemEntities[index].amount = Int64(task.amount)
                } else {
                    let newTask = DailyTaskEntity(task, context: context)
                    object.addToDailyTasks(newTask)
                }
                context.saveContext()
            } catch {
                handleError(error, operation: "updateDailyTask")
            }
        }
    }

    func toggleCompleted(_ task: DailyTask, progressIndex: Int) {
        self.coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let itemEntities = object.dailyTasks?.allObjects as? [DailyTaskEntity] ?? []
                if let index = itemEntities.firstIndex(where: { $0.id == task.id }) {
                    var progressList = (itemEntities[index].progressList as? [Bool]) ?? []
                    progressList[progressIndex] = !progressList[progressIndex]
                    itemEntities[index].progressList = progressList as NSArray
                }
                context.saveContext()
            } catch {
                handleError(error, operation: "toggleTaskCompleted")
            }
        }
    }

    func deleteTaskDelete(_ task: DailyTask) -> Single<DailyTask> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    let tasks = object.dailyTasks?.allObjects as? [DailyTaskEntity] ?? []
                    guard let task = tasks.filter({ $0.id == task.id }).first else {
                        single(.failure(CoreDataStorageError.notFound))
                        return
                    }
                    object.removeFromDailyTasks(task)
                    context.saveContext()
                    single(.success(task.toDomain()))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }
}
