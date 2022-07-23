//
//  CollectionProgressViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import Foundation
import RxSwift
import RxRelay

final class CollectionProgressViewModel {
    let coordinator: DashboardCoordinator
    
    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let selectedCategory: Observable<Category>
    }
    
    struct Output {
        let items: Observable<[Category]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        input.selectedCategory
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { category in
                self.coordinator.transition(for: .item(category: category))
            }).disposed(by: disposeBag)
        
        return Output(items: Observable.just(Category.items()))
    }
}
