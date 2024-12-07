//
//  NPCReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import ReactorKit

protocol NPCReactorDelegate: AnyObject {
    func showDetail(npc: NPC)
}

final class NPCReactor: Reactor {

    enum Action {
        case fetch
        case searchText(_ text: String)
        case selectedScope(_ title: String)
        case selectedMenu(keywords: [NPCViewController.Menu: String])
        case selectedNPC(indexPath: IndexPath)
    }

    enum Mutation {
        case setNPCs(_ npc: [NPC])
        case setAllNPCs(_ npc: [NPC])
        case setLikeNPCs(_ npc: [NPC])
        case setLoadingState(_ isLoading: Bool)
        case setScope(_ scope: NPCViewController.SearchScope)
        case detail(NPC)
    }

    struct State {
        var npcs: [NPC] = []
        var isLoading: Bool = true
    }

    let initialState: State
    var coordinator: AnimalsCoordinator?

    private var allNPCs: [NPC] = []
    private var likeNPCs: [NPC] = []
    private var currentScope: NPCViewController.SearchScope = .all
    private var currentKeywords: [NPCViewController.Menu: String] = [:]
    private var lastSearchKeyword: String = ""

    init(coordinator: AnimalsCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let allNPCs = Items.shared.npcList
                .filter { $0.isEmpty == false }
                .map { Mutation.setAllNPCs($0) }
            
            let likeNPCs = Items.shared.npcLikeList
                .map { Mutation.setLikeNPCs($0) }
            
            let loadingState = Items.shared.isLoading
                .map { Mutation.setLoadingState($0) }
            
            return .merge([
                loadingState,
                allNPCs,
                likeNPCs
            ])

        case .searchText(let text):
            lastSearchKeyword = text.lowercased()
            guard text != "" else {
                return currentNPCs()
                    .compactMap { [weak self] npcs in
                        guard let owner = self else {
                            return nil
                        }
                        return owner.filtered(npcs: npcs, keywords: owner.currentKeywords)
                    }.map { Mutation.setNPCs($0) }
            }
            return currentNPCs()
                .compactMap { [weak self] npcs in
                    guard let owner = self else {
                        return nil
                    }
                    return owner.filtered(
                        npcs: owner.search(npcs: npcs, text: text.lowercased()),
                        keywords: owner.currentKeywords
                    )
                }.map { Mutation.setNPCs($0)}

        case .selectedScope(let title):
            guard let currentScope = NPCViewController.SearchScope.transform(title)
                .flatMap({ NPCViewController.SearchScope(rawValue: $0) }) else {
                return Observable.empty()
            }
            return Observable.just(Mutation.setScope(currentScope))

        case .selectedMenu(let keywords):
            currentKeywords = keywords
            return currentNPCs()
                .compactMap { [weak self] npcs in
                    guard let owner = self else {
                        return nil
                    }
                    return owner.filtered(
                        npcs: owner.search(npcs: npcs, text: owner.lastSearchKeyword),
                        keywords: keywords
                    )
                }.map { Mutation.setNPCs($0) }

        case .selectedNPC(let indexPath):
            guard let npc = currentState.npcs[safe: indexPath.item] else {
                return Observable.empty()
            }
            return Observable.just(Mutation.detail(npc))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading

        case .setNPCs(let npcs):
            newState.npcs = search(npcs: npcs, text: lastSearchKeyword)

        case .setAllNPCs(let npcs):
            if currentScope == .all {
                newState.npcs = npcs
            }
            allNPCs = npcs

        case .setLikeNPCs(let npcs):
            if currentScope == .liked {
                newState.npcs = filtered(
                    npcs: search(npcs: npcs, text: lastSearchKeyword),
                    keywords: currentKeywords
                )
            }
            likeNPCs = npcs

        case .setScope(let scope):
            currentScope = scope

        case .detail(let npc):
            coordinator?.transition(for: .detailNPC(npc))
        }
        return newState
    }

    private func currentNPCs() -> Observable<[NPC]> {
        switch currentScope {
        case .all: return .just(allNPCs)
        case .liked: return .just(likeNPCs)
        }
    }

    private func filtered(
        npcs: [NPC],
        keywords: [NPCViewController.Menu: String]
    ) -> [NPC] {
        guard currentKeywords.isEmpty == false else {
            return npcs
        }
        var filteredData = [NPC]()
        currentKeywords = keywords
        keywords
            .sorted { $0.key.rawValue.count > $1.key.rawValue.count }
            .forEach { (key, value) in
            switch key {
            case .gender:
                let value = Gender.transform(localizedString: value) ?? ""
                filteredData = (filteredData.isEmpty ? npcs : filteredData)
                    .filter { $0.gender == Gender(rawValue: value)  }

            case .all: filteredData = npcs
            }
        }
        return filteredData
    }

    private func search(npcs: [NPC], text: String) -> [NPC] {
        guard lastSearchKeyword != "" else {
            return npcs
        }
        return npcs
            .filter {
                let npcName = $0.translations.localizedName()
                let isChosungCheck = text.isChosung
                if isChosungCheck {
                    return (npcName.contains(text) || npcName.chosung.contains(text))
                } else {
                    return npcName.contains(text)
                }
            }
    }
}
