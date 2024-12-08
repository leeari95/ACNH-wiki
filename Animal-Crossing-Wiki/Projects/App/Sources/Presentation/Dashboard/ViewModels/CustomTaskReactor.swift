//
//  CustomTaskViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import ReactorKit

final class CustomTaskReactor: Reactor {

    enum Action {
        case save
        case iconList
        case taskName(_ text: String)
        case iconName(_ text: String)
        case amount(_ text: String)
    }

    enum Mutation {
        case setName(_ text: String)
        case setAmount(_ text: String)
        case setIcon(_ text: String)
        case save
        case chooseIcon
    }

    struct State {
        var task: DailyTask?
        var title: String?
        var icon: String?
        var amount: Int?
    }

    let initialState: State
    private let storage: DailyTaskStorage = CoreDataDailyTaskStorage()
    private let coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator, task: DailyTask?) {
        self.coordinator = coordinator
        self.initialState = State(task: task)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .save:
            return Observable.just(Mutation.save)
        case .iconList:
            return Observable.just(Mutation.chooseIcon)
        case .taskName(let text):
            return Observable.just(Mutation.setName(text))
        case .iconName(let text):
            return Observable.just(Mutation.setIcon(text))
        case .amount(let text):
            return Observable.just(Mutation.setAmount(text))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setName(let name):
            newState.title = name
        case .setIcon(let name):
            newState.icon = name
        case .setAmount(let amount):
            newState.amount = Int(amount) ?? 1
        case .save:
            var newTask: DailyTask
            if let task = newState.task {
                newTask = DailyTask(
                    id: task.id,
                    name: newState.title ?? task.name,
                    icon: newState.icon ?? task.icon,
                    progressList: Array(repeating: false, count: newState.amount ?? task.amount),
                    amount: newState.amount ?? task.amount,
                    createdDate: task.createdDate
                )
            } else {
                newTask = DailyTask(
                    name: newState.title ?? "제목 없음",
                    icon: newState.icon ?? "Inv7",
                    isCompleted: false,
                    amount: newState.amount ?? 1,
                    createdDate: Date()
                )
            }
            storage.updateTask(newTask)
            Items.shared.updateTasks(newTask)
            newState.task = newTask
            coordinator.transition(for: .pop)
        case .chooseIcon:
            coordinator.transition(for: .iconChooser)
        }
        return newState
    }
}
