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
    
    private let item: Item
    private let storage: ItemsStorage
    
    init(item: Item, storage: ItemsStorage = CoreDataItemsStorage()) {
        self.item = item
        self.storage = storage
    }
    
    struct Input {
        let didTapCheck: Observable<Void>
    }
    
    struct Output {
        let item: Observable<Item>
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
            .compactMap { $0[self.item.category] }
            .subscribe(onNext: { items in
                isAcquired.accept(items.contains(where: { $0.name == self.item.name && $0.genuine == self.item.genuine }))
            }).disposed(by: disposeBag)
        
        return Output(
            item: Observable.just(item),
            isAcquired: isAcquired.asObservable()
        )
    }
    
}
