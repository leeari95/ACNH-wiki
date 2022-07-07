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
    
    private let category: Category
    private let coordinator: CatalogCoordinator?
    
    init(category: Category, coordinator: CatalogCoordinator) {
        self.category = category
        self.coordinator = coordinator
    }
    
    struct Input {
        let selectedScopeButton: Observable<String>
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
        let currentTap = BehaviorRelay<ItemsViewController.SearchScope>(value: .all)
        var allItems = [Item]()
        var userItems = [Item]()
        var currentHemisphere = Hemisphere.north
        
        Items.shared.userInfo
            .compactMap { $0 }
            .subscribe(onNext: { userInfo in
                currentHemisphere = userInfo.hemisphere
            }).disposed(by: disposeBag)
        
        Items.shared.categoryList
            .compactMap { $0[self.category] }
            .subscribe(onNext: { newItems in
                items.accept(newItems)
                allItems = newItems
            }).disposed(by: disposeBag)
        
        Items.shared.itemList
            .subscribe(onNext: { list in
                userItems = list.filter { $0.category == self.category }
                if currentTap.value == .collection {
                    items.accept(userItems)
                }
            }).disposed(by: disposeBag)
        
        input.selectedScopeButton
            .compactMap { ItemsViewController.SearchScope(rawValue: $0) }
            .subscribe(onNext: { scope in
                switch scope {
                case .all: items.accept(allItems)
                case .collection: items.accept(userItems)
                }
                currentTap.accept(scope)
            }).disposed(by: disposeBag)
        
        input.searchBarText
            .compactMap { $0 }
            .subscribe(onNext: { text in
                guard text != "" else {
                    items.accept(allItems)
                    switch currentTap.value {
                    case .all: items.accept(allItems)
                    case .collection: items.accept(userItems)
                    }
                    return
                }
                var filterItems = [Item]()
                switch currentTap.value {
                case .all: filterItems = allItems
                case .collection: filterItems = userItems
                }
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
                var filteredItems = [Item]()
                switch currentTap.value {
                case .all: filteredItems = allItems
                case .collection: filteredItems = userItems
                }
                var itemList = [Item]()
                keywords.sorted { $0.key.rawValue < $1.key.rawValue }.forEach { (key, value) in
                    switch key {
                    case .all: itemList = filteredItems
                    case .month:
                        let month = Int(value) ?? 1
                        let filteredData = filteredItems.filter {
                            if currentHemisphere == .north {
                                return $0.hemispheres.north.monthsArray.contains(month)
                            } else {
                                return $0.hemispheres.south.monthsArray.contains(month)
                            }
                        }
                        itemList = filteredData
                    case .name:
                        let filteredData = (itemList.isEmpty ? filteredItems : itemList).sorted {
                            value == ItemsViewController.Menu.ascending ?
                            $0.translations.localizedName() < $1.translations.localizedName() :
                            $0.translations.localizedName() > $1.translations.localizedName()
                        }
                        itemList = filteredData
                    case .sell:
                        let filteredData = (itemList.isEmpty ? filteredItems : itemList).sorted {
                            value == ItemsViewController.Menu.ascending ?
                            $0.sell < $1.sell : $0.sell > $1.sell
                        }
                        itemList = filteredData
                    }
                }
                items.accept(itemList)
            }).disposed(by: disposeBag)
        
        input.itemSelected
            .compactMap { items.value[safe: $0.item] }
            .withUnretained(self)
            .subscribe(onNext: { owner, item in
                owner.coordinator?.pushToItemsDetail(item)
            }).disposed(by: disposeBag)
        
        return Output(
            category: Observable.just(category),
            items: items.asObservable()
        )
    }

}
