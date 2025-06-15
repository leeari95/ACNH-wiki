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
        case toggleVariantCheck(_ variantId: String, _ isChecked: Bool)
        case loadSavedVariants(_ checkedVariants: Set<String>)
    }

    enum Mutation {
        case setAcquired(_ isAcquired: Bool)
        case updateAcquired
        case showKeywordList(title: String, keyword: Keyword)
        case showMusicPlayer
        case updateVariantCheck(_ variantId: String, _ isChecked: Bool)
        case clearAllVariants
        case loadSavedVariants(_ checkedVariants: Set<String>)
    }

    struct State {
        var item: Item
        var isAcquired: Bool = false
    }

    let initialState: State
    private let storage: ItemsStorage
    private(set) var coordinator: Coordinator?

    init(item: Item, coordinator: Coordinator?, storage: ItemsStorage = CoreDataItemsStorage()) {
        self.storage = storage
        self.coordinator = coordinator
        
        self.initialState = State(item: item)
        
        Self.loadSavedVariants(for: item, storage: storage) { [weak self] checkedVariants in
            guard let self = self else { return }
            if let checkedVariants = checkedVariants {
                self.action.onNext(.loadSavedVariants(checkedVariants))
            }
        }
    }
    
    private static func loadSavedVariants(
        for item: Item,
        storage: ItemsStorage,
        completion: @escaping (Set<String>?) -> Void
    ) {
        _ = storage.fetch().subscribe(
            onSuccess: { items in
                let savedItem = items.first { $0.name == item.name && $0.genuine == item.genuine }
                completion(savedItem?.checkedVariants)
            },
            onFailure: { _ in
                completion(nil)
            }
        )
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
            
            if currentState.isAcquired {
                var updatedItem = currentState.item
                updatedItem.checkedVariants = nil
                
                Items.shared.updateItem(updatedItem)
                storage.clearVariantsAndUpdate(updatedItem)
                
                return Observable.concat([
                    .just(.clearAllVariants),
                    .just(.updateAcquired)
                ])
            } else {
                Items.shared.updateItem(currentState.item)
                storage.update(currentState.item)
                
                if let firstVariant = currentState.item.variationsWithColor.first, 
                   currentState.item.checkedVariants?.isEmpty != false {
                    let firstVariantId = firstVariant.filename
                    storage.updateVariantCheck(item: currentState.item, variantId: firstVariantId, isChecked: true)
                    
                    return Observable.concat([
                        .just(.updateAcquired),
                        .just(.updateVariantCheck(firstVariantId, true))
                    ])
                }
                
                return .just(.updateAcquired)
            }

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
            
        case .toggleVariantCheck(let variantId, let isChecked):
            let shouldAcquire = isChecked && !currentState.isAcquired
            
            if shouldAcquire {
                HapticManager.shared.impact(style: .medium)
                storage.updateVariantCheckAndAcquire(item: currentState.item, variantId: variantId, isChecked: isChecked, shouldAcquire: true)
                return Observable.concat([
                    .just(.updateVariantCheck(variantId, isChecked)),
                    .just(.updateAcquired)
                ])
            } else {
                storage.updateVariantCheck(item: currentState.item, variantId: variantId, isChecked: isChecked)
                return .just(.updateVariantCheck(variantId, isChecked))
            }
            
        case .loadSavedVariants(let checkedVariants):
            return .just(.loadSavedVariants(checkedVariants))
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
            
        case .updateVariantCheck(let variantId, let isChecked):
            var currentCheckedVariants = newState.item.checkedVariants ?? Set<String>()
            if isChecked {
                currentCheckedVariants.insert(variantId)
            } else {
                currentCheckedVariants.remove(variantId)
            }
            newState.item.checkedVariants = currentCheckedVariants.isEmpty ? nil : currentCheckedVariants
            
        case .clearAllVariants:
            newState.item.checkedVariants = nil
            
        case .loadSavedVariants(let checkedVariants):
            newState.item.checkedVariants = checkedVariants.isEmpty ? nil : checkedVariants
        }
        return newState
    }
}
