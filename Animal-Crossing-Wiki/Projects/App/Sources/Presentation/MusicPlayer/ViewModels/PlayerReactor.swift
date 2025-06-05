//
//  PlayerViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/22.
//

import Foundation
import ReactorKit
import ACNHCore
import ACNHShared

final class PlayerReactor: Reactor {

    enum Action {
        case fetch
        case didTapMiniPlayer
        case folding
        case dragGesture(_ isSwipeUp: Bool?)
        case cancel
        case play
        case next
        case prev
        case playerList
        case selectedSong(_ item: Item)
        case shuffle
        case fullRepeat
    }

    enum Mutation {
        case setSongs(_ items: [Item])
        case transform(_ mode: PlayerMode)
        case remove
    }

    struct State {
        var playerMode: PlayerMode = .small
        var songs: [Item] = []
    }

    let initialState: State
    private let coordinator: AppCoordinator

    init(coordinator: AppCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let songs = MusicPlayerManager.shared.songList.map { Mutation.setSongs($0) }
            return songs

        case .didTapMiniPlayer:
            return .just(.transform(.large))

        case .folding:
            return .just(.transform(.small))

        case .dragGesture(
            let isSwipeUp):
            guard let isSwipeUp = isSwipeUp else {
                return .empty()
            }
            return .just(.transform(isSwipeUp ? .large : .small))

        case .cancel:
            return .just(.remove)

        case .play:
            MusicPlayerManager.shared.togglePlaying()
            return .empty()

        case .next:
            MusicPlayerManager.shared.next()
            return .empty()

        case .prev:
            MusicPlayerManager.shared.prev()
            return .empty()

        case .playerList:
            return .just(.transform(.list))

        case .selectedSong(let item):
            MusicPlayerManager.shared.choice(item)
            return .empty()

        case .shuffle:
            MusicPlayerManager.shared.updatePlayerMode(to: .shuffle)
            return .empty()

        case .fullRepeat:
            MusicPlayerManager.shared.updatePlayerMode(to: .fullRepeat)
            return .empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setSongs(let items):
            newState.songs = items

        case .transform(let mode):
            switch mode {
            case .small:
                coordinator.minimize()

            case .large:
                coordinator.maximize()

            case .list: break
            }
            newState.playerMode = mode

        case .remove:
            coordinator.removePlayerViewController()
        }
        return newState
    }
}
