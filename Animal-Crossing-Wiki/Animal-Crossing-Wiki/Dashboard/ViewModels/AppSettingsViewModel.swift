//
//  AppSettingsViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/12.
//

import Foundation
import RxSwift
import RxRelay

final class AppSettingViewModel {
    struct Input {
        let didTapSwitch: Observable<Void>
    }
    
    struct Output {
        let currentHapticState: Observable<Bool>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let state = PublishRelay<Bool>()
        input.didTapSwitch
            .subscribe(onNext: { _ in
                state.accept(HapticManager.shared.mode == .on ? false : true)
                HapticManager.shared.toggle()
            }).disposed(by: disposeBag)
        return Output(currentHapticState: state.asObservable())
    }
}
