//
//  CoreDataDailyTaskStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import CoreData

final class CoreDataDailyTaskStorage: DailyTaskStorage {
    
    private let coreDataStorage: CoreDataStorage
    
    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }
    
    func fetchTasks(completion: @escaping (Result<[DailyTask], Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let itemEntities = object?.dailyTasks?.allObjects as? [DailyTaskEntity] ?? []
                let tasks = itemEntities.map { $0.toDomain() }
                completion(.success(tasks))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func insertTask(_ task: DailyTask, completion: @escaping (Result<DailyTask, Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let newTask = DailyTaskEntity(task, context: context)
                object?.addToDailyTasks(newTask)
                context.saveContext()
                completion(.success(newTask.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
    
    func deleteTaskDelete(_ task: DailyTask, completion: @escaping (Result<DailyTask, Error>) -> Void) {
        coreDataStorage.performBackgroundTask { [weak self] context in
            do {
                let object = try self?.coreDataStorage.getUserCollection(context)
                let tasks = object?.dailyTasks?.allObjects as? [DailyTaskEntity] ?? []
                guard let task = tasks.filter({ $0.id == task.id }).first else {
                    completion(.failure(CoreDataStorageError.notFound))
                    return
                }
                object?.removeFromDailyTasks(task)
                context.saveContext()
                completion(.success(task.toDomain()))
            } catch {
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }
}

