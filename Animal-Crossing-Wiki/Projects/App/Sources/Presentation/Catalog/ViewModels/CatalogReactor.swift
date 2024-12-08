//
//  CatalogViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation
import ReactorKit

protocol CatalogReactorDelegate: AnyObject {
    func showItemList(category: Category)
    func showSearchList()
}

final class CatalogReactor: Reactor {

    enum Action {
        case fetch
        case selectedCategory(title: Category)
        case searchButtonTapped
    }

    enum Mutation {
        case showItemList(category: Category)
        case showSearchList
        case setCategories(_ categories: [(title: Category, count: Int)])
        case setLoadingState(_ isLoading: Bool)
    }

    struct State {
        var categories: [(title: Category, count: Int)] = []
        var isLoading: Bool = true
    }

    let initialState: State
    weak var delegate: CatalogReactorDelegate?
    
    let mode: Mode

    init(delegate: CatalogReactorDelegate, state: State = State(), mode: Mode = .item) {
        self.delegate = delegate
        self.initialState = state
        self.mode = mode
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let count: Observable<[Category: Int]> = Items.shared.count(isItem: mode == .item)
            let categorieList: [Category] = mode == .item ? Category.items() : Category.animals()

            let categories = count
                .map { itemsCount in categorieList.map { ($0, itemsCount[$0] ?? 0)} }
                .map { Mutation.setCategories($0) }

            let loadingState = Items.shared.isLoading
                .map { Mutation.setLoadingState($0) }

            return .merge([
                categories, loadingState
            ])

        case .selectedCategory(let category):
            return .just(.showItemList(category: category))

        case .searchButtonTapped:
            return .just(.showSearchList)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .showItemList(let category):
            delegate?.showItemList(category: category)
            
        case .showSearchList:
            delegate?.showSearchList()

        case .setCategories(let categories):
            newState.categories = categories

        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}

extension CatalogReactor {
    enum Mode {
        case animals
        case item
    }
}
