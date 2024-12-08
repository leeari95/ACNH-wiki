//
//  NPCCellReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2024/11/23.
//

import Foundation
import ReactorKit

final class NPCCellReactor: Reactor {

    enum Action {
        case fetch
        case like
    }

    enum Mutation {
        case updateLike
        case setLike(_ isLiked: Bool)
    }

    struct State {
        var isLiked: Bool?
        var isResident: Bool?
    }

    let initialState: State
    private let npc: NPC
    private let likeStorage: NPCLikeStorage

    init(
        state: State = State(),
        npc: NPC,
        likeStorage: NPCLikeStorage = CoreDataNPCLikeStorage()
    ) {
        self.initialState = state
        self.npc = npc
        self.likeStorage = likeStorage
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            return Items.shared.npcLikeList
                .take(1)
                .map { [weak self] list in
                    list.contains(where: { $0.name == self?.npc.name })
                }.map { Mutation.setLike($0) }

        case .like:
            return .just(.updateLike)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLike(let isLiked):
            newState.isLiked = isLiked

        case .updateLike:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateNPCLike(npc)
            likeStorage.update(npc)
        }
        return newState
    }
}
