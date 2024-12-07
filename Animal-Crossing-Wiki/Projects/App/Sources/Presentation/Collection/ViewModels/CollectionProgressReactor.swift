//
//  CollectionProgressViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import Foundation
import ReactorKit

final class CollectionProgressReactor: Reactor {

    enum Action {
        case selectedCategory(_ category: Category)
    }

    enum Mutation {
        case transition(DashboardCoordinator.Route)
    }

    struct State {
        let items: [Category] = Category.items()
    }

    let initialState: State
    let coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectedCategory(let category):
            return .just(.transition(.item(category: category)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .transition(let route):
            coordinator.transition(for: route)
        }
        return state
    }
}
