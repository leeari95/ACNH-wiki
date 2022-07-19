//
//  ItemDetailViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import Foundation
import RxSwift
import RxRelay

final class ItemDetailViewModel {
    
    let item: Item
    private let storage: ItemsStorage
    private(set) var coordinator: Coordinator?
    
    init(item: Item, coordinator: Coordinator?, storage: ItemsStorage = CoreDataItemsStorage()) {
        self.item = item
        self.storage = storage
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapCheck: Observable<Void>
        let didTapKeyword: Observable<String>?
    }
    
    struct Output {
        let isAcquired: Observable<Bool>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let isAcquired = BehaviorRelay<Bool>(value: false)
        
        input.didTapCheck
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                HapticManager.shared.impact(style: .medium)
                Items.shared.updateItem(owner.item)
                owner.storage.update(owner.item)
            }).disposed(by: disposeBag)

        input.didTapKeyword?
            .subscribe(onNext: { value in
                var keyword: Keyword?
                if Color.allCases.map({ $0.rawValue }).contains(value) {
                    keyword = .color
                } else if Concept.allCases.map({ $0.rawValue }).contains(value) {
                    keyword = .concept
                } else {
                    keyword = .tag
                }
                keyword.flatMap { keyword in
                    if let coordinator = self.coordinator as? CatalogCoordinator {
                        coordinator.transition(for: .keyword(title: value, keyword: keyword))
                    } else if let coordinator = self.coordinator as? DashboardCoordinator {
                        coordinator.transition(for: .keyword(title: value, keyword: keyword))
                    } else if let coordinator = self.coordinator as? CollectionCoordinator {
                        coordinator.transition(for: .keyword(title: value, keyword: keyword))
                    }
                }
            }).disposed(by: disposeBag)
        
        Items.shared.itemList
            .compactMap { $0[self.item.category] }
            .subscribe(onNext: { items in
                isAcquired.accept(items.contains(self.item))
            }).disposed(by: disposeBag)
        
        return Output(
            isAcquired: isAcquired.asObservable()
        )
    }
    
}
