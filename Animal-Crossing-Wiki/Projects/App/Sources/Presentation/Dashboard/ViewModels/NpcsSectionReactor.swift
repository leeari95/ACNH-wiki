//
//  NpcsSectionReactor.swift
//  ACNH-wiki
//
//  Created by Ari on 12/6/24.
//

import Foundation
import ReactorKit
import RxSwift
import RxCocoa
import ACNHCore
import ACNHShared

final class NpcsSectionReactor: Reactor, ObservableObject {
    enum Action {
        case fetch
        case npcLongPress(index: Int)
    }

    enum Mutation {
        case transition(route: DashboardCoordinator.Route)
        case setNpc(_ npcs: [NPC])
    }

    struct State {
        var npcs: [NPC] = []
    }

    @Published var initialState: State
    private var coordinator: DashboardCoordinator?
    private let mode: Mode

    init(state: State, mode: Mode, coordinator: DashboardCoordinator?) {
        self.initialState = state
        self.mode = mode
        self.coordinator = coordinator
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            return mode.npcs
                .map { Mutation.setNpc($0) }
                .asObservable()
            
        case .npcLongPress(let index):
            guard let npc = currentState.npcs[safe: index] else {
                return Observable.empty()
            }
            return Observable.just(Mutation.transition(route: .npcDetail(npc: npc)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .transition(route):
            coordinator?.transition(for: route)

        case let .setNpc(npcs):
            newState.npcs = npcs
            objectWillChange.send()
        }
        return newState
    }
}

extension NpcsSectionReactor {
    enum Mode {
        case fixedVisit
        case randomVisit
        
        var npcs: Driver<[NPC]> {
            switch self {
            case .fixedVisit:
                return Items.shared.fixedVisitNpcs
            case .randomVisit:
                return Items.shared.randomVisitNpcs
            }
        }
    }
}
