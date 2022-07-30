//
//  TasksEditViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import ReactorKit

final class TasksEditReactor: Reactor {
    
    enum Action {
        case fetch
        case selectedTask(_ task: DailyTask)
        case cancel
        case deleted(index: IndexPath)
    }
    
    enum Mutation {
        case setTasks(_ tasks: [DailyTask])
        case transition(DashboardCoordinator.Route)
        case deleteTask(_ index: Int)
    }
    
    struct State {
        var tasks: [DailyTask] = []
    }
    
    let initialState: State
    private let storage: DailyTaskStorage
    private let coordinator: DashboardCoordinator
    private let disposeBag = DisposeBag()
    
    init(
        coordinator: DashboardCoordinator,
        storage: DailyTaskStorage = CoreDataDailyTaskStorage(),
        state: State = State()
    ) {
        self.coordinator = coordinator
        self.storage = storage
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let tasks = Items.shared.dailyTasks.map { tasks -> Mutation in
                var tasks = tasks
                tasks.append(
                    DailyTask(
                        name: "Add a custom task",
                        icon: "plus",
                        isCompleted: false,
                        amount: 1,
                        createdDate: Date()
                    )
                )
                return Mutation.setTasks(tasks)
            }
            return tasks
            
        case .selectedTask(let task):
            return Observable.just(Mutation.transition(.customTask(task: task)))
            
        case .deleted(let indexPath):
            return Observable.just(Mutation.deleteTask(indexPath.item))
            
        case .cancel:
            return Observable.just(Mutation.transition(.dismiss))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setTasks(let tasks):
            newState.tasks = tasks
        case .transition(let route):
            coordinator.transition(for: route)
        case .deleteTask(let index):
            storage.deleteTaskDelete(newState.tasks.remove(at: index))
                .subscribe(onSuccess: { task in
                    Items.shared.deleteTask(task)
                }, onFailure: { error in
                    debugPrint(error)
                }).disposed(by: disposeBag)
        }
        return newState
    }
}
