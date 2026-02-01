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
        case fetchCollectedVariants
        case toggleVariantCollection(Variant)
    }

    enum Mutation {
        case setAcquired(_ isAcquired: Bool)
        case updateAcquired
        case showKeywordList(title: String, keyword: Keyword)
        case showMusicPlayer
        case setCollectedVariantIds(Set<String>)
        case updateVariantCollection(variantId: String, isCollected: Bool)
    }

    struct State {
        let item: Item
        var isAcquired: Bool = false
        var collectedVariantIds: Set<String> = []
    }

    let initialState: State
    private let storage: ItemsStorage
    private let variantsStorage: VariantsStorage
    private(set) var coordinator: Coordinator?

    init(item: Item, coordinator: Coordinator?, storage: ItemsStorage = CoreDataItemsStorage(), variantsStorage: VariantsStorage = CoreDataVariantsStorage()) {
        self.storage = storage
        self.variantsStorage = variantsStorage
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
                .compactMap { [weak self] items -> Mutation? in
                    guard let owner = self else {
                        return nil
                    }
                    return Mutation.setAcquired(items.contains(owner.currentState.item))
                }
            return collectedState

        case .check:
            HapticManager.shared.impact(style: .medium)
            let willBeUncollected = currentState.isAcquired

            if willBeUncollected {
                let collectedVariants = Items.shared.getCollectedVariants(for: currentState.item.name)

                variantsStorage.removeAll(for: currentState.item.name)
                collectedVariants.forEach { variantId in
                    Items.shared.updateVariant(variantId, itemName: currentState.item.name, isAdding: false)
                }

                Items.shared.updateItem(currentState.item)
                storage.update(currentState.item)

                return .from([.updateAcquired, .setCollectedVariantIds([])])
            } else {
                Items.shared.updateItem(currentState.item)
                storage.update(currentState.item)
            }

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

        case .fetchCollectedVariants:
            let itemName = currentState.item.name
            return Items.shared.variantList
                .take(1)
                .map { variantsByItem in
                    Mutation.setCollectedVariantIds(variantsByItem[itemName] ?? [])
                }

        case .toggleVariantCollection(let variant):
            HapticManager.shared.impact(style: .medium)
            let isCurrentlyCollected = currentState.collectedVariantIds.contains(variant.variantId)
            let newState = !isCurrentlyCollected

            if newState {
                variantsStorage.add(variant.variantId, itemName: currentState.item.name)
                Items.shared.updateVariant(variant.variantId, itemName: currentState.item.name, isAdding: true)

                // 아이템이 수집되지 않았다면 함께 수집 처리
                if !currentState.isAcquired {
                    Items.shared.updateItem(currentState.item)
                    storage.update(currentState.item)
                }
            } else {
                variantsStorage.remove(variant.variantId)
                Items.shared.updateVariant(variant.variantId, itemName: currentState.item.name, isAdding: false)
            }

            // Variant 체크 시 아이템도 함께 체크된 경우 두 mutation 반환
            var mutations: [Mutation] = [.updateVariantCollection(variantId: variant.variantId, isCollected: newState)]
            if newState && !currentState.isAcquired {
                mutations.append(.updateAcquired)
            }

            return .from(mutations)
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

        case .setCollectedVariantIds(let ids):
            newState.collectedVariantIds = ids

        case .updateVariantCollection(let variantId, let isCollected):
            if isCollected {
                newState.collectedVariantIds.insert(variantId)
            } else {
                newState.collectedVariantIds.remove(variantId)
            }
        }
        return newState
    }
}
