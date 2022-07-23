//
//  MusicPlayerViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/24.
//

import Foundation
import RxSwift

final class MusicPlayerViewModel {
    
    private let coordinator: DashboardCoordinator
    
    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapPlayButton: Observable<Void>
        let didTapNextButton: Observable<Void>
        let didTapPrevButton: Observable<Void>
        let didTapShuffle: Observable<Void>
        let didTapRepeat: Observable<Void>
    }
    
    struct Output {
        let currentSong: Observable<Item?>
        let isPlaying: Observable<Bool?>
        let songProgress: Observable<Float>
        let currentTime: Observable<String>
        let fullTime: Observable<String>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        input.didTapPlayButton.subscribe(onNext: { _ in
            let appCoordinator = self.coordinator.parentCoordinator as? AppCoordinator
            appCoordinator?.showPlayerViewController()
            MusicPlayerManager.shared.togglePlaying()
        }).disposed(by: disposeBag)
        
        input.didTapNextButton.subscribe(onNext: { _ in
            MusicPlayerManager.shared.next()
        }).disposed(by: disposeBag)
        
        input.didTapPrevButton
            .subscribe(onNext: { _ in
                MusicPlayerManager.shared.prev()
            }).disposed(by: disposeBag)
        
        input.didTapShuffle
            .subscribe(onNext: { _ in
                MusicPlayerManager.shared.updatePlayerMode(to: .shuffle)
            }).disposed(by: disposeBag)
        
        input.didTapRepeat
            .subscribe(onNext: { _ in
                MusicPlayerManager.shared.updatePlayerMode(to: .fullRepeat)
            }).disposed(by: disposeBag)
        
        return Output(
            currentSong: MusicPlayerManager.shared.currentMusic,
            isPlaying: MusicPlayerManager.shared.isNowPlaying,
            songProgress: MusicPlayerManager.shared.songProgress,
            currentTime: MusicPlayerManager.shared.currentTime,
            fullTime: MusicPlayerManager.shared.fullTime
        )
    }
}
