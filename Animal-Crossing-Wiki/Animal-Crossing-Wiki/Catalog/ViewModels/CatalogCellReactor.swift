//
//  CatalogRowViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import Foundation
import ReactorKit

final class CatalogCellReactor: Reactor {
    
    enum Action {
        case setAcquired(_ items: [Category: [Item]])
        case check
    }
    
    enum Mutation {
        case setAcquired(_ isAcquired: Bool)
    }
    
    struct State {
        let item: Item
        let category: Category
        var isAcquired: Bool?
    }
    
    let initialState: State
    private let item: Item
    private let category: Category
    private let storage: ItemsStorage
    
    init(
        item: Item,
        category: Category,
        state: State,
        storage: ItemsStorage = CoreDataItemsStorage()
        
    ) {
        self.item = item
        self.category = category
        self.initialState = state
        self.storage = storage
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .setAcquired(let allItems):
            guard let items = allItems[currentState.category] else {
                return Observable.empty()
            }
            return .just(.setAcquired(items.contains(item)))
            
        case .check:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateItem(item)
            storage.update(item)
            return .just(.setAcquired(currentState.isAcquired == true ? false : true))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setAcquired(let isAcquired):
            newState.isAcquired = isAcquired
        }
        return newState
    }
}
