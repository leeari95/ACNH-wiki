//
//  CollectionProgressSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import UIKit
import RxSwift

final class CollectionProgressSectionViewModel {
    var coordinator: DashboardCoordinator?
    
    init(coordinator: DashboardCoordinator?) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapSection: Observable<UITapGestureRecognizer>
    }

    func bind(input: Input, disposeBag: DisposeBag) {
        input.didTapSection
            .subscribe(onNext: { _ in
                self.coordinator?.transition(for: .progress)
            }).disposed(by: disposeBag)
    }
}
