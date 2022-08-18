//
//  ProgressReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import Foundation
import ReactorKit

final class ProgressReactor: Reactor {
    
    enum Action {
        case fetch
    }
    
    enum Mutation {
        case setItemInfo(itemCount: Int, maxCount: Int)
    }
    
    struct State {
        var itemInfo: (itemCount: Int, maxCount: Int) = (0, 0)
    }
    
    let initialState: State
    let category: Category
    
    init(category: Category) {
        self.category = category
        self.initialState = State()
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let itemsInfo = Observable.combineLatest(Items.shared.itemList, Items.shared.itemsCount)
                .map { info -> (itemCount: Int, maxCount: Int) in
                    let itemsCount = info.0[self.category]?.count ?? 0
                    let maxCount = info.1[self.category] ?? itemsCount
                    return (itemsCount, maxCount)
                }.map { Mutation.setItemInfo(itemCount: $0.itemCount, maxCount: $0.maxCount) }
            return itemsInfo
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setItemInfo(let itemCount, let maxCount):
            newState.itemInfo = (itemCount, maxCount)
        }
        return newState
    }
}
