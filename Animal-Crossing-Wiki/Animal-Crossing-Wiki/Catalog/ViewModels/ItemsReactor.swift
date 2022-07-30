//
//  ItemsViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import Foundation
import ReactorKit

final class ItemsReactor: Reactor {
    
    enum Mode: Equatable {
        case user
        case all
        case keyword(title: String, category: Keyword)
    }
    
    enum Action {
        case fetch
        case search(text: String)
        case selectedScope(_ title: String)
        case selectedMenu(keywords: [ItemsViewController.Menu: String])
        case selectedItem(indexPath: IndexPath)
    }
    
    enum Mutation {
        case setHemisphere(_ hemisphere: Hemisphere)
        case setAllItems(_ items: [Item])
        case setItems(_ items: [Item])
        case setLoadingState(_ isLoading: Bool)
        case setUserItems(collected: [Item], notCollected: [Item])
        case setScope(_ scope: ItemsViewController.SearchScope)
        case showDetail(_ item: Item)
    }
    
    struct State {
        let category: Category
        var items: [Item] = []
        var isLoading: Bool = true
    }
    
    let category: Category
    let mode: Mode
    let initialState: State
    private let coordinator: Coordinator?
    
    private var currentKeywords: [ItemsViewController.Menu: String] = [:]
    private var lastSearchKeyword: String = ""
    private var currentScope: ItemsViewController.SearchScope = .all
    private var currentHemisphere: Hemisphere = .north
    private var allItems: [Item] = []
    private var collectedItem: [Item] = []
    private var notCollectedItem: [Item] = []
    
    init(category: Category, coordinator: Coordinator?, mode: Mode = .all) {
        self.category = category
        self.initialState = State(category: category)
        self.coordinator = coordinator
        self.mode = mode
    }
    
    convenience init (coordinator: Coordinator?, mode: Mode) {
        self.init(
            category: .housewares,
            coordinator: coordinator, mode: mode
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let newAllItems = setUpItems().map { Mutation.setAllItems($0) }
            let collectedItems = setUpUserItem()
            let notCollectedIems = setUpUserItem().map { self.setUpNotCollected($0) }
            let userItems = Observable.combineLatest(collectedItems, notCollectedIems)
                .map { Mutation.setUserItems(collected: $0.0, notCollected: $0.1) }
            let loadingState = Items.shared.isLoading.map { Mutation.setLoadingState($0) }
            let hemisphere = Items.shared.userInfo.compactMap { $0?.hemisphere }
                .map { Mutation.setHemisphere($0)}
            
            return .merge([
                loadingState, hemisphere, newAllItems, userItems
            ])
            
        case .search(let text):
            lastSearchKeyword = text.lowercased()
            guard text != "" else {
                return currentItems()
                    .map { self.filtered(items: $0, keywords: self.currentKeywords) }
                    .map { .setItems($0) }
            }
            return currentItems()
                .map { self.search(items: $0, text: text.lowercased()) }
                .map { self.filtered(items: $0, keywords: self.currentKeywords) }
                .map { .setItems($0)}
            
        case .selectedScope(let title):
            guard let currentScope = ItemsViewController.SearchScope.transform(title)
                .flatMap({ ItemsViewController.SearchScope(rawValue: $0) }) else {
                return .empty()
            }
            return .just(.setScope(currentScope))
            
        case .selectedMenu(let keywords):
            currentKeywords = keywords
            return currentItems()
                .map { self.filtered(items: $0, keywords: keywords) }
                .map { self.search(items: $0, text: self.lastSearchKeyword) }
                .map { .setItems($0) }
            
        case .selectedItem(let indexPath):
            guard let item = currentState.items[safe: indexPath.item] else {
                return .empty()
            }
            return .just(.showDetail(item))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setItems(let items):
            newState.items = items
        
        case .setHemisphere(let hemisphere):
            currentHemisphere = hemisphere
            
        case .setAllItems(let items):
            if currentScope == .all {
                newState.items = items
            }
            allItems = items
            
        case .setUserItems(let collectedItems, let notCollectedItems):
            if currentScope == .collected {
                newState.items = filtered(
                    items: search(items: collectedItems, text: lastSearchKeyword),
                    keywords: self.currentKeywords
                )
            }
            if currentScope == .notCollected {
                newState.items = filtered(
                    items: search(items: notCollectedItems, text: lastSearchKeyword),
                    keywords: self.currentKeywords
                )
            }
            collectedItem = collectedItems
            notCollectedItem = notCollectedItems
            
        case .setScope(let scope):
            currentScope = scope
            
        case .showDetail(let item):
            if let coordinator = self.coordinator as? CatalogCoordinator {
                coordinator.transition(for: .itemDetail(item))
            } else if let coordinator = self.coordinator as? CollectionCoordinator {
                coordinator.transition(for: .itemDetail(item: item))
            } else if let coordinator = self.coordinator as? DashboardCoordinator {
                coordinator.transition(for: .itemDetail(item: item))
            }
        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading
            
        }
        return newState
    }
    
    private func currentItems() -> Observable<[Item]> {
        guard allItems.isEmpty == false else {
            return Observable.empty()
        }
        switch currentScope {
        case .all: return .just(allItems)
        case .collected: return .just(collectedItem)
        case .notCollected: return .just(notCollectedItem)
        }
    }
    
    private func filtered(
        items: [Item],
        keywords: [ItemsViewController.Menu: String]
    ) -> [Item] {
        guard currentKeywords.isEmpty == false else {
            return items
        }
        currentKeywords = keywords
        var filteredItems = items
        let keywords = keywords.sorted { $0.key.rawValue < $1.key.rawValue }
        for (key, value) in keywords {
            switch key {
            case .all:
                continue
            case .month:
                let month = Int(value) ?? 1
                filteredItems = items.filter {
                    currentHemisphere == .north ?
                    ($0.hemispheres?.north.monthsArray ?? []).contains(month) :
                    ($0.hemispheres?.south.monthsArray ?? []).contains(month)
                }
            case .name:
                filteredItems = (filteredItems.isEmpty ? items : filteredItems).sorted {
                        value == ItemsViewController.Menu.ascending ?
                        $0.translations.localizedName() < $1.translations.localizedName() :
                        $0.translations.localizedName() > $1.translations.localizedName()
                    }
            case .sell:
                filteredItems = (filteredItems.isEmpty ? items : filteredItems).sorted {
                        value == ItemsViewController.Menu.ascending ?
                        $0.sell < $1.sell : $0.sell > $1.sell
                    }
            }
        }
        return filteredItems
    }
    
    private func search(items: [Item], text: String) -> [Item] {
        guard lastSearchKeyword != "" else {
            return items
        }
        return items
            .filter {
                let villagerName = $0.translations.localizedName().lowercased()
                let isChosungCheck = text.isChosung
                if isChosungCheck {
                    return (villagerName.contains(text) || villagerName.chosung.contains(text))
                } else {
                    return villagerName.contains(text)
                }
            }
    }
    
    private func setUpItems() -> Observable<[Item]> {
        switch mode {
        case .all, .user:
            return Items.shared.categoryList
                .compactMap { $0[self.currentState.category] }
            
        case .keyword(let title, let category):
            let filteredData = Items.shared.itemFilter(keyword: title, category: category)
            return .just(filteredData)
        }
    }
    
    private func setUpUserItem() ->  Observable<[Item]> {
        switch mode {
        case .all:
            return Items.shared.itemList
                .map { $0[self.currentState.category] ?? [] }
            
        case .keyword(let title, _):
            return Items.shared.itemList
                .map { $0.values.flatMap { $0.filter { $0.keyword.contains(title) } } }
            
        default:
            return .empty()
        }
    }
    
    private func setUpNotCollected(_ items: [Item]) -> [Item] {
        var notCollectedItems = [Item]()
        if items.isEmpty {
            notCollectedItems = allItems
        } else {
            notCollectedItems = Array(
                Set(allItems).symmetricDifference(Set(items))
            ).sorted(by: { $0.name < $1.name })
        }
        return notCollectedItems
    }
}
