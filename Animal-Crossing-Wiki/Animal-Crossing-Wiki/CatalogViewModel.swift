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
        let catagories: [(Category, Int)] = Category.items().map { ($0, Items.shared.itemsCount(category: $0)) }
        
        input.selectedCategory
            .map { $0.title }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { category in
                self.coordinator?.pushToItems(category: category)
            }).disposed(by: disposeBag)
        
        return Output(catagories: Observable.just(catagories))
    }
}
