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
        let didTapPlayList: Observable<Void>
        let seletedSong: Observable<Item>
    }
    
    struct Output {
        let playerMode: Observable<PlayerMode?>
        let songs: Observable<[Item]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let playerMode = BehaviorRelay<PlayerMode?>(value: nil)
        let songs = BehaviorRelay<[Item]>(value: [])
        
        input.didTapMiniPlayer
            .subscribe(onNext: { _ in
                self.coordinator.maximize()
                playerMode.accept(.large)
            }).disposed(by: disposeBag)
        
        input.didTapFoldingButton
            .subscribe(onNext: { _ in
                self.coordinator.minimize()
                playerMode.accept(.small)
            }).disposed(by: disposeBag)
        
        input.dragGesture
            .compactMap { $0 }
            .subscribe(onNext: { isSwipeUp in
                if isSwipeUp {
                    self.coordinator.maximize()
                    playerMode.accept(.large)
                } else {
                    self.coordinator.minimize()
                    playerMode.accept(.small)
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
        
        input.didTapPlayList
            .subscribe(onNext: { _ in
                playerMode.accept(.list)
            }).disposed(by: disposeBag)
        
        input.seletedSong
            .subscribe(onNext: { item in
                MusicPlayerManager.shared.choice(item)
            }).disposed(by: disposeBag)
        
        MusicPlayerManager.shared.songList
            .subscribe(onNext: { items in
                songs.accept(items)
            }).disposed(by: disposeBag)
        
        return Output(playerMode: playerMode.asObservable(), songs: songs.asObservable())
    }
}
