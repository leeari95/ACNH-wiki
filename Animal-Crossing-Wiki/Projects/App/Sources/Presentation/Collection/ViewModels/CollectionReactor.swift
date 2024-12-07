//
//  CollectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import Foundation
import ReactorKit

final class CollectionReactor: Reactor {

    enum Action {
        case fetch
        case selectedCategory(title: Category)
    }

    enum Mutation {
        case setCategories(_ categories: [(title: Category, count: Int)])
        case transition(CollectionCoordinator.Route)
    }

    struct State {
        var catagories: [(title: Category, count: Int)] = []
    }

    let initialState: State
    let coordinator: CollectionCoordinator

    init(coordinator: CollectionCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let categories = Items.shared.itemList
                .map { items -> Mutation in
                    let categoryList = items.keys.sorted { $0.rawValue < $1.rawValue }
                    var newCategories = [(title: Category, count: Int)]()
                    for category in categoryList where items[category]?.count != .zero {
                        newCategories.append((category, items[category]?.count ?? 0))
                    }
                    return Mutation.setCategories(newCategories)
                }
            return categories

        case .selectedCategory(let category):
            return .just(Mutation.transition(.items(category: category, mode: .user)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCategories(let categories):
            newState.catagories = categories.sorted(by: <)

        case .transition(let route):
            coordinator.transition(for: route)
        }
        return newState
    }
}
