//
//  DashboardViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import Foundation
import RxSwift

final class DashboardViewModel {
    var coordinator: DashboardCoordinator?
    
    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapMore: Observable<Void>
    }
    
    func bind(input: Input, disposeBag: DisposeBag) {
        input.didTapMore
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.coordinator?.rootViewController.visibleViewController?
                    .showSelectedItemAlert(
                        ["About".localized, "Setting".localized],
                        currentItem: nil
                    ).subscribe(onNext: { selected in
                        if selected == "Setting".localized {
                            self.coordinator?.transition(for: .setting)
                        } else if selected == "About".localized {
                            self.coordinator?.transition(for: .about)
                        }
                    }).disposed(by: disposeBag)
            }).disposed(by: disposeBag)
    }
}
