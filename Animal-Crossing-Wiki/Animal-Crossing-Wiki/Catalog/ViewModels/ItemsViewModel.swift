//
//  ItemsViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import Foundation
import RxSwift
import RxRelay

final class ItemsViewModel {
    enum Mode: Equatable {
        case user
        case all
        case keyword(title: String, category: Keyword)
    }
    
    let category: Category
    let mode: Mode
    private let coordinator: Coordinator?
    
    init(category: Category, coordinator: Coordinator?, mode: Mode = .all) {
        self.category = category
        self.coordinator = coordinator
        self.mode = mode
    }
    
    convenience init (coordinator: Coordinator?, mode: Mode) {
        self.init(category: .housewares, coordinator: coordinator, mode: mode)
    }
    
    struct Input {
        let searchBarText: Observable<String?>
        let didSelectedMenuKeyword: Observable<[ItemsViewController.Menu: String]>
        let itemSelected: Observable<IndexPath>
        let seletedScopeButton: Observable<String>
    }
    struct Output {
        let category: Observable<Category>
        let items: Observable<[Item]>
        let isLoading: Observable<Bool>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let items = BehaviorRelay<[Item]>(value: [])
        var allItems = [Item]()
        var collectedItems = [Item]()
        var notCollectedItems = [Item]()
        var currentHemisphere = Hemisphere.north
        let currentTap = BehaviorRelay<ItemsViewController.SearchScope>(value: .all)
        let currentFilter = BehaviorRelay<[ItemsViewController.Menu: String]>(value: [:])
        let currentSearchBarText = BehaviorRelay<String>(value: "")
        let isLoading = BehaviorRelay<Bool>(value: true)
        
        Items.shared.userInfo
            .compactMap { $0 }
            .subscribe(onNext: { userInfo in
                currentHemisphere = userInfo.hemisphere
            }).disposed(by: disposeBag)
        
        input.seletedScopeButton
            .compactMap { ItemsViewController.SearchScope.transform($0) }
            .compactMap { ItemsViewController.SearchScope(rawValue: $0) }
            .subscribe(onNext: { seletedScope in
                currentTap.accept(seletedScope)
            }).disposed(by: disposeBag)
        
        input.searchBarText
            .compactMap { $0 }
            .subscribe(onNext: { text in
                currentSearchBarText.accept(text)
            }).disposed(by: disposeBag)
        
        currentSearchBarText
            .subscribe(onNext: { text in
                guard text != "" else {
                    switch currentTap.value {
                    case .all: items.accept(allItems)
                    case .notCollected: items.accept(notCollectedItems)
                    case .collected: items.accept(collectedItems)
                    }
                    return
                }
                isLoading.accept(true)
                var filteredItems = [Item]()
                switch currentTap.value {
                case .all: filteredItems = allItems
                case .notCollected: filteredItems = notCollectedItems
                case .collected: filteredItems = collectedItems
                }
                let text = text.lowercased()
                filteredItems = filteredItems
                    .filter {
                        let itemName = $0.translations.localizedName().lowercased()
                        let isChosungCheck = text.isChosung
                        if isChosungCheck {
                            return (itemName.contains(text) || itemName.chosung.contains(text))
                        } else {
                            return itemName.contains(text)
                        }
                    }
                items.accept(filteredItems)
                isLoading.accept(false)
            }).disposed(by: disposeBag)
        
        input.didSelectedMenuKeyword
            .subscribe(onNext: { keywords in
                currentFilter.accept(keywords)
            }).disposed(by: disposeBag)
        
        currentFilter
            .subscribe(onNext: { keywords in
                isLoading.accept(true)
                var currentItems = [Item]()
                switch currentTap.value {
                case .all: currentItems = allItems
                case .notCollected: currentItems = notCollectedItems
                case .collected: currentItems = collectedItems
                }
                var sortedItems = currentItems
                let keywords = keywords.sorted { $0.key.rawValue < $1.key.rawValue }
                for (key, value) in keywords {
                    switch key {
                    case .all:
                        continue
                    case .month:
                        let month = Int(value) ?? 1
                        let filteredData = sortedItems.filter {
                            currentHemisphere == .north ?
                            ($0.hemispheres?.north.monthsArray ?? []).contains(month) :
                            ($0.hemispheres?.south.monthsArray ?? []).contains(month)
                        }
                        sortedItems = filteredData
                    case .name:
                        let filteredData = sortedItems.sorted {
                                value == ItemsViewController.Menu.ascending ?
                                $0.translations.localizedName() < $1.translations.localizedName() :
                                $0.translations.localizedName() > $1.translations.localizedName()
                            }
                        sortedItems = filteredData
                    case .sell:
                        let filteredData = sortedItems.sorted {
                                value == ItemsViewController.Menu.ascending ?
                                $0.sell < $1.sell : $0.sell > $1.sell
                            }
                        sortedItems = filteredData
                    }
                }
                if currentSearchBarText.value != "" {
                    let text = currentSearchBarText.value.lowercased()
                    sortedItems = sortedItems.filter {
                            let itemName = $0.translations.localizedName().lowercased()
                            let isChosungCheck = text.isChosung
                            if isChosungCheck {
                                return (itemName.contains(text) || itemName.chosung.contains(text))
                            } else {
                                return itemName.contains(text)
                            }
                        }
                }
                items.accept(sortedItems)
                isLoading.accept(false)
            }).disposed(by: disposeBag)
        
        input.itemSelected
            .compactMap { items.value[safe: $0.item] }
            .subscribe(onNext: { item in
                if let coordinator = self.coordinator as? CatalogCoordinator {
                    coordinator.transition(for: .itemDetail(item))
                } else if let coordinator = self.coordinator as? CollectionCoordinator {
                    coordinator.transition(for: .itemDetail(item: item))
                } else if let coordinator = self.coordinator as? DashboardCoordinator {
                    coordinator.transition(for: .itemDetail(item: item))
                }
            }).disposed(by: disposeBag)
        
        setUpItems(disposeBag)
            .subscribe(onNext: { newItems in
                guard newItems.isEmpty == false else {
                    let coordinator = self.coordinator as? CollectionCoordinator
                    coordinator?.transition(for: .pop)
                    return
                }
                isLoading.accept(true)
                items.accept(newItems)
                allItems = newItems
                isLoading.accept(false)
            }).disposed(by: disposeBag)
        
        setUpUserItems(disposeBag)?
            .subscribe(onNext: { userItems in
                collectedItems = userItems
                if userItems.isEmpty {
                    notCollectedItems = allItems
                } else {
                    let notCollected = Array(
                        Set(allItems).symmetricDifference(Set(collectedItems))
                    ).sorted(by: { $0.name < $1.name })
                    notCollectedItems = notCollected
                }
                currentFilter.accept(currentFilter.value)
                currentSearchBarText.accept(currentSearchBarText.value)
            }).disposed(by: disposeBag)
        
        return  Output(
            category: Observable.just(category),
            items: items.asObservable(),
            isLoading: isLoading.asObservable()
        )
    }
    
    private func setUpItems(_ disposeBag: DisposeBag) -> Observable<[Item]> {
        let items = BehaviorRelay<[Item]>(value: [])
        switch mode {
        case .all:
            Items.shared.categoryList
                .compactMap { $0[self.category] }
                .subscribe(onNext: { newItems in
                    items.accept(newItems)
                }).disposed(by: disposeBag)
        case .user:
            Items.shared.itemList
                .compactMap { $0[self.category] }
                .subscribe(onNext: { newItems in
                    items.accept(newItems)
                }).disposed(by: disposeBag)
        case .keyword(let title, let category):
            let filteredData = Items.shared.itemFilter(keyword: title, category: category)
            items.accept(filteredData)
        }
        return items.asObservable()
    }
    
    private func setUpUserItems(_ disposeBag: DisposeBag) -> Observable<[Item]>? {
        let items = BehaviorRelay<[Item]>(value: [])
        switch mode {
        case .all:
            Items.shared.itemList
                .compactMap { $0[self.category] }
                .subscribe(onNext: { userItems in
                    items.accept(userItems)
                }).disposed(by: disposeBag)
        case .keyword(let title, _):
            Items.shared.itemList
                .compactMap { $0.values.flatMap { $0.filter { $0.keyword.contains(title) } } }
                .subscribe(onNext: { userItems in
                    items.accept(userItems)
                }).disposed(by: disposeBag)
        default: return nil
        }
        return items.asObservable()
    }
    
}
