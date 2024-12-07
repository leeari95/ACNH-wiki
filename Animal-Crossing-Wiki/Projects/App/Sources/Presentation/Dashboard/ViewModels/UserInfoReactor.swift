//
//  UserInfoReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/08/01.
//

import Foundation
import ReactorKit

final class UserInfoReactor: Reactor {

    enum Action {
        case fetch
        case tap
    }

    enum Mutation {
        case transition(route: DashboardCoordinator.Route)
        case setUserInfo(_ userInfo: UserInfo)
    }

    struct State {
        var userInfo: UserInfo?
    }

    let initialState: State
    let coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let userInfo = Items.shared.userInfo
                .compactMap { $0 }
                .map { Mutation.setUserInfo($0) }
            return userInfo

        case .tap:
            return .just(.transition(route: .setting))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setUserInfo(let userInfo):
            newState.userInfo = userInfo

        case .transition(let route):
            coordinator.transition(for: route)
        }
        return newState
    }
}
