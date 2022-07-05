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
    
    init(category: Category) {
        self.category = category
    }
    
    struct Input {
        
    }
    struct Output {
        let category: Observable<Category>
        let items: Observable<[Item]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let items = BehaviorRelay<[Item]>(value: [])
        Items.shared.categoryList
            .compactMap { $0[self.category] }
            .subscribe(onNext: { newItems in
                items.accept(newItems)
            }).disposed(by: disposeBag)
        
        return Output(
            category: Observable.just(category),
            items: items.asObservable()
        )
    }

}
