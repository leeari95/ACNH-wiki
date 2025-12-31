//
//  ItemDetailViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import Foundation
import ReactorKit

final class ItemDetailReactor: Reactor {

    enum Action {
        case fetch
        case check
        case didTapKeyword(_ keyword: String)
        case play
        case checkVariant(_ variantId: String)
    }

    enum Mutation {
        case setAcquired(_ isAcquired: Bool)
        case updateAcquired
        case showKeywordList(title: String, keyword: Keyword)
        case showMusicPlayer
        case setCheckedVariants(_ checkedVariants: Set<String>)
        case toggleVariant(_ variantId: String)
    }

    struct State {
        var item: Item
        var isAcquired: Bool = false
        var checkedVariants: Set<String> = []
    }

    let initialState: State
    private let storage: ItemsStorage
    private(set) var coordinator: Coordinator?

    init(item: Item, coordinator: Coordinator?, storage: ItemsStorage = CoreDataItemsStorage()) {
        self.storage = storage
        self.coordinator = coordinator
        self.initialState = State(item: item)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let collectedState = Items.shared.itemList
                .take(1)
                .compactMap { [weak self] items -> [Item]? in
                    guard let owner = self else {
                        return nil
                    }
                    return items[owner.currentState.item.category]
                }
                .compactMap { [weak self] items -> (isAcquired: Bool, checkedVariants: Set<String>)? in
                    guard let owner = self else {
                        return nil
                    }
                    let currentItem = owner.currentState.item
                    if let storedItem = items.first(where: { $0 == currentItem }) {
                        return (true, storedItem.checkedVariants ?? [])
                    }
                    return (false, [])
                }
                .flatMap { result -> Observable<Mutation> in
                    return Observable.concat([
                        .just(.setAcquired(result.isAcquired)),
                        .just(.setCheckedVariants(result.checkedVariants))
                    ])
                }
            return collectedState

        case .check:
            HapticManager.shared.impact(style: .medium)
            var updatedItem = currentState.item
            updatedItem.checkedVariants = currentState.checkedVariants.isEmpty ? nil : currentState.checkedVariants
            Items.shared.updateItem(updatedItem)
            storage.update(updatedItem)
            return .just(.updateAcquired)

        case .didTapKeyword(let value):
            var keyword: Keyword = .tag
            if Color.allCases.map({ $0.rawValue }).contains(value) {
                keyword = .color
            } else if Concept.allCases.map({ $0.rawValue }).contains(value) {
                keyword = .concept
            } else {
                keyword = .tag
            }
            return .just(.showKeywordList(title: value, keyword: keyword))

        case .play:
            return .just(.showMusicPlayer)

        case .checkVariant(let variantId):
            HapticManager.shared.impact(style: .light)
            return .just(.toggleVariant(variantId))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setAcquired(let isAcquired):
            newState.isAcquired = isAcquired

        case .updateAcquired:
            newState.isAcquired = newState.isAcquired == true ? false : true

        case .showKeywordList(let title, let keyword):
            if let coordinator = coordinator as? CatalogCoordinator {
                coordinator.transition(for: .keyword(title: title, keyword: keyword))
            } else if let coordinator = coordinator as? DashboardCoordinator {
                coordinator.transition(for: .keyword(title: title, keyword: keyword))
            } else if let coordinator = coordinator as? CollectionCoordinator {
                coordinator.transition(for: .keyword(title: title, keyword: keyword))
            }

        case .showMusicPlayer:
            if let coordinator = coordinator as? CatalogCoordinator {
                let coordinator = coordinator.parentCoordinator as? AppCoordinator
                coordinator?.showMusicPlayer()
            } else if let coordinator = coordinator as? DashboardCoordinator {
                let coordinator = coordinator.parentCoordinator as? AppCoordinator
                coordinator?.showMusicPlayer()
            } else if let coordinator = coordinator as? CollectionCoordinator {
                let coordinator = coordinator.parentCoordinator as? AppCoordinator
                coordinator?.showMusicPlayer()
            }
            MusicPlayerManager.shared.choice(currentState.item)

        case .setCheckedVariants(let checkedVariants):
            newState.checkedVariants = checkedVariants

        case .toggleVariant(let variantId):
            if newState.checkedVariants.contains(variantId) {
                newState.checkedVariants.remove(variantId)
            } else {
                newState.checkedVariants.insert(variantId)
            }
            newState.item.checkedVariants = newState.checkedVariants.isEmpty ? nil : newState.checkedVariants
            storage.updateVariants(newState.item)
            Items.shared.updateItemVariants(newState.item)
        }
        return newState
    }
}
