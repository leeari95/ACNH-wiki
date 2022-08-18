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
        case progress
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
            let loadingState = Items.shared.isLoading.map { Mutation.setLoadingState($0) }
            return loadingState
            
        case .didTapSection:
            return Observable.just(Mutation.progress)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .progress:
            coordinator.transition(for: .progress)
        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
