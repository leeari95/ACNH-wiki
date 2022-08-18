//
//  AboutViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import Foundation
import ReactorKit

final class AboutReactor: Reactor {
    
    enum Action {
        case cancel
    }
    
    enum Mutation {
        case transition(for: DashboardCoordinator.Route)
    }
    
    struct State {
        var items: [(title: String, items: [AboutItem])] = [
            ("Version".localized, AboutItem.versions),
            ("The app".localized, AboutItem.theApp),
            ("Credit / Thanks".localized, AboutItem.acknowledgement)
        ]
    }
    
    let initialState: State = State()
    let coordinator: DashboardCoordinator
    
    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .cancel:
            return Observable.just(Mutation.transition(for: .dismiss))
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
