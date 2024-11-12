//
//  VillagersSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import ReactorKit

final class VillagersSectionReactor: Reactor {

    enum Action {
        case fetch
        case villagerLongPress(indexPath: IndexPath)
    }

    enum Mutation {
        case transition(route: DashboardCoordinator.Route)
        case setVillagers(_ villagers: [Villager])
    }

    struct State {
        var villagers: [Villager] = []
    }

    let initialState: State = State()
    private var coordinator: DashboardCoordinator?

    init(coordinator: DashboardCoordinator?) {
        self.coordinator = coordinator
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let villagers = Items.shared.villagerHouseList
                .map { Mutation.setVillagers($0)}
            return villagers

        case .villagerLongPress(let indexPath):
            guard let villager = currentState.villagers[safe: indexPath.item] else {
                return Observable.empty()
            }
            return Observable.just(Mutation.transition(route: .villagerDetail(villager: villager)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .transition(let route):
            coordinator?.transition(for: route)
        case .setVillagers(let villagers):
            newState.villagers = villagers
        }
        return newState
    }
}
