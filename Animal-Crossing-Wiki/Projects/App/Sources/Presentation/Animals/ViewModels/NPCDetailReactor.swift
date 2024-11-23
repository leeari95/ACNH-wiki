//
//  NPCDetailReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation
import ReactorKit

final class NPCDetailReactor: Reactor {

    enum Action {
        case fetch
        case like
    }

    enum Mutation {
        case updateLike
        case setLike(_ isLiked: Bool)
    }

    struct State {
        let npc: NPC
        var isLiked: Bool?
        var isResident: Bool?
    }

    let initialState: State
    private let likeStorage: NPCLikeStorage
    private let npc: NPC

    init(
        npc: NPC,
        state: State,
        likeStorage: NPCLikeStorage = CoreDataNPCLikeStorage()
    ) {
        self.npc = npc
        self.initialState = state
        self.likeStorage = likeStorage
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let likeState = Items.shared.npcLikeList
                .take(1)
                .map { [weak self] npcs in
                    npcs.contains(where: { $0.name == self?.npc.name })
                }.map { Mutation.setLike($0) }
            return .merge([
                likeState
            ])

        case .like:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateNPCLike(npc)
            likeStorage.update(npc)
            return .just(.updateLike)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLike(let isLiked):
            newState.isLiked = isLiked

        case .updateLike:
            newState.isLiked = newState.isLiked == true ? false : true
        }
        return newState
    }
}
