//
//  AboutViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import Foundation
import RxSwift

final class AboutViewModel {
    var coordinator: DashboardCoordinator?
    
    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapCancel: Observable<Void>
    }
    
    struct Output {
        let items: Observable<[(title: String, items: [AboutItem])]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let items: Observable<[(title: String, items: [AboutItem])]> = Observable.just([
            ("Version", AboutItem.versions),
            ("The app", AboutItem.theApp),
            ("Credit / Thanks", AboutItem.acknowledgement)
        ])
        
        input.didTapCancel
            .subscribe(onNext: { _ in
                self.coordinator?.transition(for: .dismiss)
            }).disposed(by: disposeBag)
        
        return Output(items: items)
    }
}
