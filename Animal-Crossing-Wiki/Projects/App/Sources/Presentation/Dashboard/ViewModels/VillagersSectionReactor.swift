//
//  VillagersSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import ReactorKit
import ACNHCore
import ACNHShared

final class VillagersSectionReactor: Reactor {

    enum Action {
        case fetch
        case villagerLongPress(indexPath: IndexPath)
        case villagersChecked(checked: Villager)
        case resetCheckedVillagers
    }

    enum Mutation {
        case transition(route: DashboardCoordinator.Route)
        case setVillagers(_ villagers: [Villager])
        case setCheckedVillager(_ villagers: Villager)
        case resetCheckedVillagers
    }

    struct State {
        var villagers: [Villager] = []
        var checkedVillagers: [Villager] = []
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
            
        case let .villagersChecked(checkedVillager):
            return Observable.just(Mutation.setCheckedVillager(checkedVillager))
            
        case .resetCheckedVillagers:
            return Observable.just(Mutation.resetCheckedVillagers)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .transition(let route):
            coordinator?.transition(for: route)
        case .setVillagers(let villagers):
            newState.villagers = villagers
        case let .setCheckedVillager(villager):
            if let index = newState.checkedVillagers.firstIndex(where: { $0.name == villager.name }) {
                newState.checkedVillagers.remove(at: index)
            } else {
                newState.checkedVillagers.append(villager)
            }
        case .resetCheckedVillagers:
            newState.checkedVillagers = []
        }
        return newState
    }
}
