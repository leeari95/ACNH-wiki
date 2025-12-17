//
//  TurnipPricesReactor.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import Foundation
import ReactorKit

final class TurnipPricesReactor: Reactor {

    enum Action {
        case fetch
    }

    enum Mutation {
        
    }

    struct State {
        
    }

    let initialState: State
    var coordinator: TurnipPricesCoordinator?

    init(coordinator: TurnipPricesCoordinator, state: State) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            return .empty()

        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
            
        }
        
        return newState
    }
}
