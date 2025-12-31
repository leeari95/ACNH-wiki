//
//  CollectionProgressSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import Foundation
import ReactorKit

final class CollectionProgressSectionReactor: Reactor {

    enum Action {
        case fetch
        case didTapSection
    }

    enum Mutation {
        case setLoadingState(_ isLoading: Bool)
    }

    struct State {
        var isLoading: Bool = true
    }

    let initialState: State
    var coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            return Items.shared.isLoading.map { Mutation.setLoadingState($0) }

        case .didTapSection:
            coordinator.transition(for: .progress)
            return Observable.empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
