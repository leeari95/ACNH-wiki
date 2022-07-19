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
    enum Mode {
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
        var filteredItems = [Item]()
        var currentHemisphere = Hemisphere.north
        var currentFilter = [ItemsViewController.Menu]()
        let isLoading = BehaviorRelay<Bool>(value: true)
        
        Items.shared.userInfo
            .compactMap { $0 }
            .subscribe(onNext: { userInfo in
                currentHemisphere = userInfo.hemisphere
            }).disposed(by: disposeBag)
        
        input.searchBarText
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
            .compactMap { $0 }
            .subscribe(onNext: { text in
                guard text != "" else {
                    items.accept(filteredItems.isEmpty ? allItems : filteredItems)
                    return
                }
                isLoading.accept(true)
                let text = text.lowercased()
                let filteredData = (filteredItems.isEmpty ? allItems : filteredItems)
                    .filter {
                        let itemName = $0.translations.localizedName().lowercased()
                        let isChosungCheck = text.isChosung
                        if isChosungCheck {
                            return (itemName.contains(text) || itemName.chosung.contains(text))
                        } else {
                            return itemName.contains(text)
                        }
                    }
                items.accept(filteredData)
                isLoading.accept(false)
            }).disposed(by: disposeBag)
        
        input.didSelectedMenuKeyword
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { keywords in
                isLoading.accept(true)
                var itemList = [Item]()
                currentFilter = keywords.keys.sorted(by: { $0.rawValue < $1.rawValue })
                keywords.sorted { $0.key.rawValue < $1.key.rawValue }.forEach { (key, value) in
                    switch key {
                    case .all:
                        itemList = allItems
                        currentFilter = [key]
                    case .month:
                        let month = Int(value) ?? 1
                        let filteredData = allItems.filter {
                            currentHemisphere == .north ?
                            ($0.hemispheres?.north.monthsArray ?? []).contains(month) :
                            ($0.hemispheres?.south.monthsArray ?? []).contains(month)
                        }
                        itemList = filteredData
                    case .collected:
                        if currentFilter.contains(.month) {
                            let filteredData = itemList.filter { collectedItems.contains($0) }
                            itemList = filteredData
                        } else {
                            itemList = collectedItems
                        }
                    case .notCollected:
                        if currentFilter.contains(.month) {
                            let filteredData = itemList.filter { !collectedItems.contains($0) }
                            itemList = filteredData
                        } else {
                            itemList = notCollectedItems.isEmpty ? itemList.isEmpty ? allItems : itemList : notCollectedItems
                        }
                        
                    case .name:
                        let filteredData = (itemList.isEmpty ? filteredItems : itemList)
                            .sorted {
                                value == ItemsViewController.Menu.ascending ?
                                $0.translations.localizedName() < $1.translations.localizedName() :
                                $0.translations.localizedName() > $1.translations.localizedName()
                            }
                        itemList = filteredData
                    case .sell:
                        let filteredData = (itemList.isEmpty ? filteredItems : itemList)
                            .sorted {
                                value == ItemsViewController.Menu.ascending ?
                                $0.sell < $1.sell : $0.sell > $1.sell
                            }
                        itemList = filteredData
                    }
                }
                items.accept(itemList)
                filteredItems = itemList
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
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
            .filter { !$0.isEmpty }
            .subscribe(onNext: { newItems in
                isLoading.accept(true)
                items.accept(newItems)
                allItems = newItems
            }).disposed(by: disposeBag)
        
        setUpUserItems(disposeBag)
            .subscribe(onNext: { userItems in
                collectedItems = userItems
                let notCollected = allItems.filter { !collectedItems.contains($0) }
                notCollectedItems = notCollected
                if currentFilter.contains(.notCollected) {
                    let filteredData = (filteredItems.isEmpty ? notCollected : filteredItems)
                        .filter { !collectedItems.contains($0) }
                    items.accept(filteredData)
                    filteredItems = filteredData
                }
                isLoading.accept(false)
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
    
    private func setUpUserItems(_ disposeBag: DisposeBag) -> Observable<[Item]> {
        let items = BehaviorRelay<[Item]>(value: [])
        switch mode {
        case .all, .user:
            Items.shared.itemList
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
                .compactMap { $0[self.category] }
                .subscribe(onNext: { userItems in
                    items.accept(userItems)
                }).disposed(by: disposeBag)
        case .keyword(let title, _):
            Items.shared.itemList
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
                .compactMap { $0.values.flatMap { $0.filter { $0.keyword.contains(title) } } }
                .subscribe(onNext: { userItems in
                    items.accept(userItems)
                }).disposed(by: disposeBag)
        }
        return items.asObservable()
    }
    
}
