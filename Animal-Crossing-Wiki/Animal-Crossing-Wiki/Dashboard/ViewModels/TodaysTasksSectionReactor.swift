//
//  TodaysTasksSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import ReactorKit

final class TodaysTasksSectionReactor: Reactor {
    
    enum Action {
        case fetch
        case selectedItem(indexPath: IndexPath)
        case reset
        case edit
    }
    
    enum Mutation {
        case transition(route: DashboardCoordinator.Route)
        case toggleCompleted(index: Int)
        case reset
        case setTasks(_ tasks: [DailyTask])
    }
    
    struct State {
        var tasks: [(progressIndex: Int, task: DailyTask)] = []
    }
    
    let initialState: State
    private let coordinator: DashboardCoordinator
    private let storage: DailyTaskStorage
    
    init(coordinator: DashboardCoordinator, storage: DailyTaskStorage = CoreDataDailyTaskStorage()) {
        self.coordinator = coordinator
        self.storage = storage
        self.initialState = State()
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let tasks = Items.shared.dailyTasks.map { Mutation.setTasks($0) }
            return tasks
        case .selectedItem(let indexPath):
            return Observable.just(Mutation.toggleCompleted(index: indexPath.item))
        case .reset:
            return Observable.just(Mutation.reset)
        case .edit:
            return Observable.just(Mutation.transition(route: .taskEdit))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setTasks(let tasks):
            var tasksList = [(progressIndex: Int, task: DailyTask)]()
            tasks.forEach { task in
                (0..<task.amount).forEach { index in
                    tasksList.append((index, task))
                }
            }
            newState.tasks = tasksList
        case .transition(let route):
            coordinator.transition(for: route)
        case .toggleCompleted(let index):
            guard let item = newState.tasks[safe: index] else {
                break
            }
            storage.toggleCompleted(item.task, progressIndex: item.progressIndex)
            newState.tasks[index].task.toggleCompleted(item.progressIndex)
        case .reset:
            newState.tasks.enumerated().forEach { (index, tuple) in
                var tuple = tuple
                tuple.task.reset()
                newState.tasks[index] = tuple
                storage.updateTask(tuple.task)
            }
        }
        
        return newState
    }
}
