//
//  CollectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import Foundation
import RxSwift
import RxRelay

final class CollectionViewModel {
    var coordinator: CollectionCoordinator?
    
    init(coordinator: CollectionCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let selectedCategory: Observable<(title: Category, count: Int)>
    }
    
    struct Output {
        let catagories: Observable<[(title: Category, count: Int)]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let categories = BehaviorRelay<[(title: Category, count: Int)]>(value: [])
        
        Items.shared.itemList
            .subscribe(onNext: { items in
                let currentCategories = items.keys
                categories.accept(
                    currentCategories
                        .sorted { $0.rawValue < $1.rawValue }
                        .map { category in
                            return (category, items[category]?.count ?? 0)
                    }
                )
            }).disposed(by: disposeBag)
        
        input.selectedCategory
            .map { $0.title }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { category in
                self.coordinator?.pushToItems(category: category)
            }).disposed(by: disposeBag)
        
        return Output(catagories: categories.asObservable())
    }
    
}
