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
        let didTapAbout: Observable<Void>
        let didTapSetting: Observable<Void>
    }
    
    func bind(input: Input, disposeBag: DisposeBag) {
        input.didTapAbout
            .subscribe(onNext: { _ in
                self.coordinator?.transition(for: .about)
            }).disposed(by: disposeBag)
        
        input.didTapSetting
            .subscribe(onNext: { _ in
                self.coordinator?.transition(for: .setting)
            }).disposed(by: disposeBag)
    }
}
