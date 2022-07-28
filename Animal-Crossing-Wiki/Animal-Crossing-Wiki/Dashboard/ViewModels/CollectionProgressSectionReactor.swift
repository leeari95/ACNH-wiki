//
//  CollectionProgressSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import UIKit
import ReactorKit

final class CollectionProgressSectionReactor: Reactor {
    
    enum Action {
        case didTapSection
    }
    
    enum Mutation {
        case progress
    }
    
    struct State {}
    
    let initialState: State
    var coordinator: DashboardCoordinator
    
    init(coordinator: DashboardCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .didTapSection:
            return Observable.just(Mutation.progress)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .progress:
            coordinator.transition(for: .progress)
        }
        return state
    }
}
