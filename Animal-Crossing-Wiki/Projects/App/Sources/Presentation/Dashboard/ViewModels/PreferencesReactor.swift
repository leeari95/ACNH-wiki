//
//  PreferencesSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/21.
//

import Foundation
import ReactorKit

final class PreferencesReactor: Reactor {

    enum Action {
        case islandName(_ text: String?)
        case userName(_ text: String?)
        case hemishphere(title: String)
        case fruit(title: String)
        case reputation(_ score: String?)
        case cancel
    }

    enum Mutation {
        case transition(for: DashboardCoordinator.Route)
        case setUserName(_ name: String?)
        case setIslandName(_ name: String?)
        case setHemishphere(_ hemishphere: Hemisphere?)
        case setFruit(_ fruit: Fruit?)
        case setReputation(_ reputation: Int)
    }

    struct State {
        var userInfo: UserInfo?
    }

    let initialState: State
    private let coordinator: DashboardCoordinator
    private let storage: UserInfoStorage

    init(coordinator: DashboardCoordinator, storage: UserInfoStorage = CoreDataUserInfoStorage()) {
        self.coordinator = coordinator
        self.storage = storage
        self.initialState = State(userInfo: storage.fetchUserInfo())
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .islandName(let text):
            return .just(.setIslandName(text))
        case .userName(let text):
            return .just(.setUserName(text))
        case .hemishphere(let title):
            let hemishphere = Hemisphere.transform(title) ?? ""
            return .just(.setHemishphere(Hemisphere(rawValue: hemishphere)))
        case .fruit(let title):
            let fruit = Fruit.transform(title) ?? ""
            return .just(.setFruit(Fruit(rawValue: fruit)))
        case .reputation(let score):
            return .just(.setReputation((score?.count ?? 1) - 1))
        case .cancel:
            return .just(.transition(for: .dismiss))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setUserName(let name):
            name.flatMap { newState.userInfo?.updateName($0) }
        case .setIslandName(let name):
            name.flatMap { newState.userInfo?.updateIslandName($0) }
        case .setFruit(let fruit):
            fruit.flatMap { newState.userInfo?.updateFruit($0) }
        case .setHemishphere(let hemishphere):
            hemishphere.flatMap { newState.userInfo?.updateHemisphere($0) }
        case .setReputation(let reputation):
            newState.userInfo?.updateIslandReputation(reputation)
        case .transition(let route):
            coordinator.transition(for: route)
        }
        if newState.userInfo != state.userInfo {
            newState.userInfo.flatMap {
                storage.updateUserInfo($0)
                Items.shared.updateUserInfo($0)
            }
        }
        return newState
    }
}
