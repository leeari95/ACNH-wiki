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
        case selectedCategory(title: Category)
        case setCategories(_ categories: [(title: Category, count: Int)])
    }
    
    enum Mutation {
        case transition(CatalogCoordinator.Route)
        case setCategories(_ categories: [(title: Category, count: Int)])
    }
    
    struct State {
        var categories: [(title: Category, count: Int)] = []
    }
    
    let initialState: State
    var coordinator: CatalogCoordinator
    
    init(coordinator: CatalogCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectedCategory(let category):
            return .just(.transition(.items(for: category)))
            
        case .setCategories(let categories):
            return .just(.setCategories(categories))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .transition(let route):
            coordinator.transition(for: route)
            
        case .setCategories(let categories):
            newState.categories = categories
        }
        return newState
    }
}
