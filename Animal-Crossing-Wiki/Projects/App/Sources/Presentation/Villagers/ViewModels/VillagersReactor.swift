//
//  VillagersViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import ReactorKit

final class VillagersReactor: Reactor {

    enum Action {
        case fetch
        case searchText(_ text: String)
        case selectedScope(_ title: String)
        case selectedMenu(keywords: [VillagersViewController.Menu: String])
        case selectedVillager(indexPath: IndexPath)
    }

    enum Mutation {
        case setVillagers(_ villagers: [Villager])
        case setAllVillagers(_ villagers: [Villager])
        case setLikeVillagers(_ villagers: [Villager])
        case setHouseVillagers(_ villagers: [Villager])
        case setLoadingState(_ isLoading: Bool)
        case setScope(_ scope: VillagersViewController.SearchScope)
        case transition(route: VillagersCoordinator.Route)
    }

    struct State {
        var villagers: [Villager] = []
        var isLoading: Bool = true
    }

    let initialState: State
    var coordinator: VillagersCoordinator?

    private var allVillagers: [Villager] = []
    private var likeVillagers: [Villager] = []
    private var houseVillagers: [Villager] = []
    private var currentScope: VillagersViewController.SearchScope = .all
    private var currentKeywords: [VillagersViewController.Menu: String] = [:]
    private var lastSearchKeyword: String = ""

    init(coordinator: VillagersCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let allVillagers = Items.shared.villagerList
                .filter { $0.isEmpty == false }
                .map { Mutation.setAllVillagers($0) }
            let likeVillagers = Items.shared.villagerLikeList.map { Mutation.setLikeVillagers($0) }
            let houseVillagers = Items.shared.villagerHouseList.map { Mutation.setHouseVillagers($0) }
            let loadingState = Items.shared.isLoading.map { Mutation.setLoadingState($0) }
            return .merge([
                loadingState,
                allVillagers,
                likeVillagers,
                houseVillagers
            ])

        case .searchText(let text):
            lastSearchKeyword = text.lowercased()
            guard text != "" else {
                return currentVillagers()
                    .compactMap { [weak self] villagers in
                        guard let owner = self else {
                            return nil
                        }
                        return owner.filtered(villagers: villagers, keywords: owner.currentKeywords)
                    }.map { Mutation.setVillagers($0) }
            }
            return currentVillagers()
                .compactMap { [weak self] villagers in
                    guard let owner = self else {
                        return nil
                    }
                    return owner.filtered(
                        villagers: owner.search(villagers: villagers, text: text.lowercased()),
                        keywords: owner.currentKeywords
                    )
                }.map { Mutation.setVillagers($0)}

        case .selectedScope(let title):
            guard let currentScope = VillagersViewController.SearchScope.transform(title)
                .flatMap({ VillagersViewController.SearchScope(rawValue: $0) }) else {
                return Observable.empty()
            }
            return Observable.just(Mutation.setScope(currentScope))

        case .selectedMenu(let keywords):
            currentKeywords = keywords
            return currentVillagers()
                .compactMap { [weak self] villagers in
                    guard let owner = self else {
                        return nil
                    }
                    return owner.filtered(
                        villagers: owner.search(villagers: villagers, text: owner.lastSearchKeyword),
                        keywords: keywords
                    )
                }.map { Mutation.setVillagers($0) }

        case .selectedVillager(let indexPath):
            guard let villager = currentState.villagers[safe: indexPath.item] else {
                return Observable.empty()
            }
            return Observable.just(Mutation.transition(route: .detail(villager: villager)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading

        case .setVillagers(let villagers):
            newState.villagers = search(villagers: villagers, text: lastSearchKeyword)

        case .setAllVillagers(let villagers):
            if currentScope == .all {
                newState.villagers = villagers
            }
            allVillagers = villagers

        case .setLikeVillagers(let villagers):
            if currentScope == .liked {
                newState.villagers = filtered(
                    villagers: search(villagers: villagers, text: lastSearchKeyword),
                    keywords: currentKeywords
                )
            }
            likeVillagers = villagers

        case .setHouseVillagers(let villagers):
            if currentScope == .residents {
                newState.villagers = filtered(
                    villagers: search(villagers: villagers, text: lastSearchKeyword),
                    keywords: currentKeywords
                )
            }
            houseVillagers = villagers

        case .setScope(let scope):
            currentScope = scope

        case .transition(let route):
            coordinator?.transition(for: route)
        }
        return newState
    }

    private func currentVillagers() -> Observable<[Villager]> {
        switch currentScope {
        case .all: return .just(allVillagers)
        case .liked: return .just(likeVillagers)
        case .residents: return .just(houseVillagers)
        }
    }

    private func filtered(
        villagers: [Villager],
        keywords: [VillagersViewController.Menu: String]
    ) -> [Villager] {
        guard currentKeywords.isEmpty == false else {
            return villagers
        }
        var filteredData = [Villager]()
        currentKeywords = keywords
        keywords
            .sorted { $0.key.rawValue.count > $1.key.rawValue.count }
            .forEach { (key, value) in
            switch key {
            case .personality:
                let value = Personality.transform(localizedString: value) ?? ""
                filteredData = villagers.filter { $0.personality == Personality(rawValue: value) }

            case .gender:
                let value = Gender.transform(localizedString: value) ?? ""
                filteredData = (filteredData.isEmpty ? villagers : filteredData)
                    .filter { $0.gender == Gender(rawValue: value)  }

            case .type:
                filteredData = (filteredData.isEmpty ? villagers : filteredData)
                    .filter { $0.subtype == Subtype(rawValue: value) }

            case .species:
                let value = Specie.transform(localizedString: value) ?? ""
                filteredData = (filteredData.isEmpty ? villagers : filteredData)
                    .filter { $0.species == Specie(rawValue: value) }

            case .all: filteredData = villagers
            }
        }
        return filteredData
    }

    private func search(villagers: [Villager], text: String) -> [Villager] {
        guard lastSearchKeyword != "" else {
            return villagers
        }
        return villagers
            .filter {
                let villagerName = $0.translations.localizedName()
                let isChosungCheck = text.isChosung
                if isChosungCheck {
                    return (villagerName.contains(text) || villagerName.chosung.contains(text))
                } else {
                    return villagerName.contains(text)
                }
            }
    }
}
