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
    var coordinator: CollectionCoordinator?
    
    init(coordinator: CollectionCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let selectedCategory: Observable<Category>
        let didTapCancel: Observable<Void>
    }
    
    struct Output {
        let items: Observable<[Category]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        input.selectedCategory
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { category in
                self.coordinator?.transition(for: .items(category: category, mode: .all))
            }).disposed(by: disposeBag)
        
        input.didTapCancel
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.coordinator?.transition(for: .dismiss)
            }).disposed(by: disposeBag)
        
        return Output(items: Observable.just(Category.items()))
    }
}
