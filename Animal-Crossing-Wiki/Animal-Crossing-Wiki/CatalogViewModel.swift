//
//  CatalogViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation
import RxSwift
import RxRelay

final class CatalogViewModel {
    var coordinator: CatalogCoordinator?
    
    init(coordinator: CatalogCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let selectedCategory: Observable<(title: Category, count: Int)>
    }
    
    struct Output {
        let catagories: Observable<[(title: Category, count: Int)]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let catagories = BehaviorRelay<[(title: Category, count: Int)]>(value: [])
        
        Items.shared.itemsCount.subscribe(onNext: { itemsCount in
            let newCategories = Category.items().map { ($0, itemsCount[$0] ?? 0)}
            catagories.accept(newCategories)
        }).disposed(by: disposeBag)
        
        input.selectedCategory
            .map { $0.title }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { category in
                self.coordinator?.transition(for: .items(for: category))
            }).disposed(by: disposeBag)
        
        return Output(catagories: catagories.asObservable())
    }
}
