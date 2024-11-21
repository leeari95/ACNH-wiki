//
//  CatalogViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation
import ReactorKit

final class CatalogReactor: Reactor {

    enum Action {
        case fetch
        case selectedCategory(title: Category)
        case searchButtonTapped
    }

    enum Mutation {
        case transition(CatalogCoordinator.Route)
        case setCategories(_ categories: [(title: Category, count: Int)])
        case setLoadingState(_ isLoading: Bool)
    }

    struct State {
        var categories: [(title: Category, count: Int)] = []
        var isLoading: Bool = true
    }

    let initialState: State
    var coordinator: CatalogCoordinator

    init(coordinator: CatalogCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let categories = Items.shared.itemsCount
                .map { itemsCount in Category.items().map { ($0, itemsCount[$0] ?? 0)} }
                .map { Mutation.setCategories($0) }
            let loadingState = Items.shared.isLoading
                .map { Mutation.setLoadingState($0) }

            return .merge([
                categories, loadingState
            ])

        case .selectedCategory(let category):
            return .just(.transition(.items(for: category)))
            
        case .searchButtonTapped:
            return .just(.transition(.search))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .transition(let route):
            coordinator.transition(for: route)

        case .setCategories(let categories):
            newState.categories = categories

        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
