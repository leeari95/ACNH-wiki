//
//  ProgressViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import Foundation
import RxSwift
import RxRelay

final class ProgressViewModel {
    let category: Category
    
    init(category: Category) {
        self.category = category
    }
    
    struct Output {
        let items: Observable<(itemCount: Int, maxCount: Int)>
    }
    
    func transform(disposeBag: DisposeBag) -> Output {
        let items = BehaviorRelay<(itemCount: Int, maxCount: Int)>(value: (0, 0))
        
        Observable.combineLatest(Items.shared.itemList, Items.shared.itemsCount)
            .map { ($0.0[self.category]?.count ?? 0, $0.1[self.category] ?? 0) }
            .filter { $0.1 != 0 }
            .subscribe(onNext: { userItemCount, maxCount in
                items.accept((userItemCount, maxCount))
            }).disposed(by: disposeBag)
        
        return Output(
            items: items.asObservable()
        )
    }
}
