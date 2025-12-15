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

final class NpcsSectionReactor: Reactor, ObservableObject {
    enum Action {
        case fetch
        case npcLongPress(index: Int)
        case npcChecked(index: Int)
        case resetCheckedNpcs
    }

    enum Mutation {
        case transition(route: DashboardCoordinator.Route)
        case setNpc(_ npcs: [NPC])
        case setCheckedNpc(_ npc: NPC)
        case resetCheckedNpcs
    }

    struct State {
        var npcs: [NPC] = []
        var checkedNpcs: [NPC] = []
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

        case .npcChecked(let index):
            guard let npc = currentState.npcs[safe: index] else {
                return .empty()
            }
            return .just(Mutation.setCheckedNpc(npc))

        case .resetCheckedNpcs:
            return .just(Mutation.resetCheckedNpcs)
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

        case let .setCheckedNpc(npc):
            if let index = newState.checkedNpcs.firstIndex(where: { $0.name == npc.name }) {
                newState.checkedNpcs.remove(at: index)
            } else {
                newState.checkedNpcs.append(npc)
            }

        case .resetCheckedNpcs:
            newState.checkedNpcs = []
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
