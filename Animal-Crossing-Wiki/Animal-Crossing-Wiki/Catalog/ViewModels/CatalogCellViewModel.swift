//
//  CatalogRowViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import Foundation
import RxSwift
import RxRelay

final class CatalogCellViewModel {
    
    private let item: Item
    private let category: Category
    private let storage: ItemsStorage
    
    init(
        item: Item,
        category: Category,
        storage: ItemsStorage = CoreDataItemsStorage()
        
    ) {
        self.item = item
        self.category = category
        self.storage = storage
    }
    
    struct Input {
        let didTapCheck: Observable<Void>
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
        
        Items.shared.itemList
            .compactMap { $0[self.category] }
            .subscribe(onNext: { items in
                isAcquired.accept(items.contains(self.item))
            }).disposed(by: disposeBag)
        
        return Output(
            isAcquired: isAcquired.asObservable()
        )
    }
    
}
