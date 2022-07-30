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
        case setHemisphere(_ hemisphere: Hemisphere)
        case setItems(_ items: [Item])
        case setColletedItems(_ items: [Item])
        case search(text: String)
        case selectedScope(_ title: String)
        case selectedMenu(keywords: [ItemsViewController.Menu: String])
        case selectedItem(indexPath: IndexPath)
    }
    
    enum Mutation {
        case setHemisphere(_ hemisphere: Hemisphere)
        case setAllItems(_ items: [Item])
        case setItems(_ items: [Item])
        case setUserItems(collected: [Item], notCollected: [Item])
        case setScope(_ scope: ItemsViewController.SearchScope)
        case showDetail(_ item: Item)
    }
    
    struct State {
        let category: Category
        var currentScope: ItemsViewController.SearchScope = .all
        var currentHemisphere: Hemisphere = .north
        var items: [Item] = []
        var allItems: [Item] = []
        var collectedItem: [Item] = []
        var notCollectedItem: [Item] = []
    }
    
    let category: Category
    let mode: Mode
    let initialState: State
    private let coordinator: Coordinator?
    
    private var currentKeywords: [ItemsViewController.Menu: String] = [:]
    private var lastSearchKeyword: String = ""
    
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
        case .setItems(let items):
            return .just(.setAllItems(items))
            
        case .setHemisphere(let hemisphere):
            return .just(.setHemisphere(hemisphere))
            
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
            
        case .setColletedItems(let collected):
            guard currentState.allItems.isEmpty == false else {
                return .empty()
            }
            let collectedItems = collected
            var notCollectedItems = [Item]()
            if collected.isEmpty {
                notCollectedItems = currentState.allItems
            } else {
                notCollectedItems = Array(
                    Set(currentState.allItems).symmetricDifference(Set(collectedItems))
                ).sorted(by: { $0.name < $1.name })
            }
            return .just(.setUserItems(collected: collectedItems, notCollected: notCollectedItems))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setItems(let items):
            newState.items = items
        
        case .setHemisphere(let hemisphere):
            newState.currentHemisphere = hemisphere
            
        case .setAllItems(let items):
            if currentState.currentScope == .all {
                newState.items = items
            }
            newState.allItems = items
            
        case .setUserItems(let collected, let notCollected):
            if currentState.currentScope == .collected {
                newState.items = filtered(
                    items: search(items: collected, text: lastSearchKeyword),
                    keywords: self.currentKeywords
                )
                
            }
            if currentState.currentScope == .notCollected {
                newState.items = filtered(
                    items: search(items: notCollected, text: lastSearchKeyword),
                    keywords: self.currentKeywords
                )
            }
            newState.collectedItem = collected
            newState.notCollectedItem = notCollected
            
        case .setScope(let scope):
            newState.currentScope = scope
            
        case .showDetail(let item):
            if let coordinator = self.coordinator as? CatalogCoordinator {
                coordinator.transition(for: .itemDetail(item))
            } else if let coordinator = self.coordinator as? CollectionCoordinator {
                coordinator.transition(for: .itemDetail(item: item))
            } else if let coordinator = self.coordinator as? DashboardCoordinator {
                coordinator.transition(for: .itemDetail(item: item))
            }
        }
        return newState
    }
    
    private func currentItems() -> Observable<[Item]> {
        guard currentState.allItems.isEmpty == false else {
            return Observable.empty()
        }
        switch currentState.currentScope {
        case .all: return .just(currentState.allItems)
        case .collected: return .just(currentState.collectedItem)
        case .notCollected: return .just(currentState.notCollectedItem)
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
                    currentState.currentHemisphere == .north ?
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
}
