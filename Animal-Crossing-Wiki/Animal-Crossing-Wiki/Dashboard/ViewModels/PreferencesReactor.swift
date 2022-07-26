//
//  PreferencesSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/21.
//

import Foundation
import RxSwift
import RxRelay
import ReactorKit

final class PreferencesReactor: Reactor {
    
    enum Action {
        case islandName(_ text: String?)
        case userName(_ text: String?)
        case hemishphere(title: String)
        case fruit(title: String)
        case cancel
    }
    
    enum Mutation {
        case transition(for: DashboardCoordinator.Route)
        case setUserName(_ name: String?)
        case setIslandName(_ name: String?)
        case setHemishphere(_ hemishphere: Hemisphere?)
        case setFruit(_ fruit: Fruit?)
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
            return Observable.just(Mutation.setIslandName(text))
        case .userName(let text):
            return Observable.just(Mutation.setUserName(text))
        case .hemishphere(let title):
            let hemishphere = Hemisphere.transform(title) ?? ""
            return Observable.just(Mutation.setHemishphere(Hemisphere(rawValue: hemishphere)))
        case .fruit(let title):
            let fruit = Fruit.transform(title) ?? ""
            return Observable.just(Mutation.setFruit(Fruit(rawValue: fruit)))
        case .cancel:
            return Observable.just(Mutation.transition(for: .dismiss))
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
        case .transition(let route):
            self.coordinator.transition(for: route)
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
