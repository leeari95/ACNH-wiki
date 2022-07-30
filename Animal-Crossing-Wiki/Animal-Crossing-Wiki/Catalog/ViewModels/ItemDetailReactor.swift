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
    }
    
    enum Mutation {
        case setAcquired(_ isAcquired: Bool)
        case updateAcquired
        case showKeywordList(title: String, keyword: Keyword)
        case showMusicPlayer
    }
    
    struct State {
        let item: Item
        var isAcquired: Bool = false
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
                .compactMap { $0[self.currentState.item.category] }
                .map { ItemDetailReactor.Mutation.setAcquired($0.contains(self.currentState.item)) }
            return collectedState

        case .check:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateItem(currentState.item)
            storage.update(currentState.item)
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
            if let coordinator = self.coordinator as? CatalogCoordinator {
                coordinator.transition(for: .keyword(title: title, keyword: keyword))
            } else if let coordinator = self.coordinator as? DashboardCoordinator {
                coordinator.transition(for: .keyword(title: title, keyword: keyword))
            } else if let coordinator = self.coordinator as? CollectionCoordinator {
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
        }
        return newState
    }
}
