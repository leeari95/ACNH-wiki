//
//  PlayerViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/22.
//

import Foundation
import RxSwift
import RxRelay

final class PlayerViewModel {
    
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapMiniPlayer: Observable<Void>
        let didTapFoldingButton: Observable<Void>
        let dragGesture: Observable<Bool?>
        let didTapCancel: Observable<Void>
        let didTapPlayButton: [Observable<Void>]
        let didTapNextButton: [Observable<Void>]
        let didTapPrevButton: Observable<Void>
    }
    
    struct Output {
        let isMinimized: Observable<Bool?>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let isMinimized = BehaviorRelay<Bool?>(value: nil)
        
        input.didTapMiniPlayer
            .subscribe(onNext: { _ in
                self.coordinator.maximize()
                isMinimized.accept(false)
            }).disposed(by: disposeBag)
        
        input.didTapFoldingButton
            .subscribe(onNext: { _ in
                self.coordinator.minimize()
                isMinimized.accept(true)
            }).disposed(by: disposeBag)
        
        input.dragGesture
            .compactMap { $0 }
            .subscribe(onNext: { isSwipeUp in
                if isSwipeUp {
                    self.coordinator.maximize()
                    isMinimized.accept(false)
                } else {
                    self.coordinator.minimize()
                    isMinimized.accept(true)
                }
            }).disposed(by: disposeBag)
        
        input.didTapCancel
            .subscribe(onNext: { _ in
                self.coordinator.removePlayerViewController()
            }).disposed(by: disposeBag)
        
        input.didTapPlayButton.forEach { observable in
            observable.subscribe(onNext: { _ in
                MusicPlayerManager.shared.togglePlaying()
            }).disposed(by: disposeBag)
        }
        
        input.didTapNextButton.forEach { observable in
            observable.subscribe(onNext: { _ in
                MusicPlayerManager.shared.next()
            }).disposed(by: disposeBag)
        }
        
        input.didTapPrevButton
            .subscribe(onNext: { _ in
                MusicPlayerManager.shared.prev()
            }).disposed(by: disposeBag)
        
        return Output(isMinimized: isMinimized.asObservable())
    }
}
