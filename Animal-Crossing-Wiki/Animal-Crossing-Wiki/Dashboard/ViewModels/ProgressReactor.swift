//
//  ProgressReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import Foundation
import RxSwift
import RxRelay
import ReactorKit

final class ProgressReactor: Reactor {
    
    enum Action {
        case updateItemsList([Category: [Item]], [Category: Int])
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
        case .updateItemsList(let userItemList, let itemsMaxCount):
            guard let maxCount = itemsMaxCount[self.category] else {
                return Observable.empty()
            }
            let itemCount = userItemList[self.category]?.count ?? 0
            return Observable.just(Mutation.setItemInfo(itemCount: itemCount, maxCount: maxCount))
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
