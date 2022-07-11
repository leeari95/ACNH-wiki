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
        let didTapRightBarButton: Observable<Void>
    }
    
    struct Output {
        let catagories: Observable<[(title: Category, count: Int)]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let categories = BehaviorRelay<[(title: Category, count: Int)]>(value: [])
        
        Items.shared.itemList
            .subscribe(onNext: { items in
                let categoryList = items.keys.sorted { $0.rawValue < $1.rawValue }
                var newCategories = [(title: Category, count: Int)]()
                for category in categoryList where items[category]?.count != .zero {
                    newCategories.append((category, items[category]?.count ?? 0))
                }
                categories.accept(newCategories)
            }).disposed(by: disposeBag)
        
        input.selectedCategory
            .map { $0.title }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { category in
                self.coordinator?.transition(for: .items(category: category, mode: .user))
            }).disposed(by: disposeBag)
        
        input.didTapRightBarButton
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { owner, _ in
                owner.coordinator?.transition(for: .progress)
        }).disposed(by: disposeBag)
        
        return Output(catagories: categories.asObservable())
    }
    
}
