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
    }
    
    let category: Category
    let mode: Mode
    private let coordinator: Coordinator?
    
    init(category: Category, coordinator: Coordinator?, mode: Mode = .all) {
        self.category = category
        self.coordinator = coordinator
        self.mode = mode
    }
    
    struct Input {
        let searchBarText: Observable<String?>
        let didSelectedMenuKeyword: Observable<[ItemsViewController.Menu: String]>
        let itemSelected: Observable<IndexPath>
    }
    struct Output {
        let category: Observable<Category>
        let items: Observable<[Item]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let items = BehaviorRelay<[Item]>(value: [])
        var allItems = [Item]()
        var collectedItems = [Item]()
        var notCollectedItems = [Item]()
        var filteredItems = [Item]()
        var currentHemisphere = Hemisphere.north
        var currentFilter = [ItemsViewController.Menu]()
        
        Items.shared.userInfo
            .compactMap { $0 }
            .subscribe(onNext: { userInfo in
                currentHemisphere = userInfo.hemisphere
            }).disposed(by: disposeBag)
        
        input.searchBarText
            .compactMap { $0 }
            .subscribe(onNext: { text in
                guard text != "" else {
                    items.accept(filteredItems.isEmpty ? allItems : filteredItems)
                    return
                }
                var filterItems = filteredItems.isEmpty ? allItems : filteredItems
                filterItems = filterItems
                    .filter {
                        let itemName = $0.translations.localizedName()
                        let isChosungCheck = text.isChosung
                        if isChosungCheck {
                            return (itemName.contains(text) || itemName.chosung.contains(text))
                        } else {
                            return itemName.contains(text)
                        }
                    }
                items.accept(filterItems)
            }).disposed(by: disposeBag)
        
        input.didSelectedMenuKeyword
            .subscribe(onNext: { keywords in
                var itemList = [Item]()
                if keywords.keys.contains(.notCollected) == false {
                    for item in collectedItems where !filteredItems.contains(where: {
                        $0.name == item.name && $0.genuine == item.genuine
                    }) {
                        filteredItems.append(item)
                    }
                }
                if keywords.keys.contains(.collected) == false {
                    for item in notCollectedItems where !filteredItems.contains(where: {
                        $0.name == item.name && $0.genuine == item.genuine
                    }) {
                        filteredItems.append(item)
                    }
                }
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
                            $0.hemispheres.north.monthsArray.contains(month) :
                            $0.hemispheres.south.monthsArray.contains(month)
                        }
                        itemList = filteredData
                    case .collected:
                        if currentFilter.contains(.month) {
                            let filteredData = itemList.filter { item in
                                collectedItems.contains(where: { $0.name == item.name && $0.genuine == item.genuine })
                            }
                            itemList = filteredData
                        } else {
                            itemList = collectedItems
                        }
                    case .notCollected:
                        if currentFilter.contains(.month) {
                            let filteredData = itemList.filter { item in
                                !collectedItems.contains(where: { $0.name == item.name && $0.genuine == item.genuine })
                            }
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
            }).disposed(by: disposeBag)
        
        input.itemSelected
            .compactMap { items.value[safe: $0.item] }
            .withUnretained(self)
            .subscribe(onNext: { owner, item in
                if let coordinator = owner.coordinator as? CatalogCoordinator {
                    coordinator.transition(for: .itemDetail(item))
                } else if let coordinator = owner.coordinator as? CollectionCoordinator {
                    coordinator.transition(for: .itemDetail(item: item))
                } else if let coordinator = owner.coordinator as? DashboardCoordinator {
                    coordinator.transition(for: .itemDetail(item: item))
                }
            }).disposed(by: disposeBag)
        
        if mode == .all {
            Items.shared.categoryList
                .compactMap { $0[self.category] }
                .subscribe(onNext: { newItems in
                    items.accept(newItems)
                    allItems = newItems
                }).disposed(by: disposeBag)
            
            Items.shared.itemList
                .compactMap { $0[self.category] }
                .subscribe(onNext: { userItems in
                    collectedItems = userItems
                    let notCollected = allItems.filter { item in
                        !collectedItems.contains(where: { $0.name == item.name && $0.genuine == item.genuine })
                    }
                    notCollectedItems = notCollected
                    if currentFilter.contains(.notCollected) {
                        let filteredData = (filteredItems.isEmpty ? notCollected : filteredItems)
                            .filter { item in
                                !collectedItems.contains(where: { $0.name == item.name && $0.genuine == item.genuine })
                            }
                        items.accept(filteredData)
                        filteredItems = filteredData
                    }
                }).disposed(by: disposeBag)
            
        } else {
            Items.shared.itemList
                .compactMap { $0[self.category] }
                .subscribe(onNext: { newItems in
                    items.accept(newItems)
                    allItems = newItems
                }).disposed(by: disposeBag)
        }
        
        return  Output(
            category: Observable.just(category),
            items: items.asObservable()
        )
    }
    
}
