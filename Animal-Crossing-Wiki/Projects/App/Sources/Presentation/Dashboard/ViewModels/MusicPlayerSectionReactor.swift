//
//  MusicPlayerSectionReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import Foundation
import ReactorKit

final class MusicPlayerSectionReactor: Reactor {

    enum Action {
        case playPauseTapped
        case previousTapped
        case nextTapped
    }

    enum Mutation {
        case setCurrentSong(Item?)
        case setIsPlaying(Bool)
        case setProgress(Float)
        case setSongsAvailable(Bool)
    }

    struct State {
        var currentSong: Item?
        var isPlaying: Bool = false
        var progress: Float = 0
        var isSongsAvailable: Bool = false
    }

    let initialState: State = State()
    private let musicPlayerManager: MusicPlayerManager

    init(musicPlayerManager: MusicPlayerManager = .shared) {
        self.musicPlayerManager = musicPlayerManager
    }

    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let currentSongMutation = musicPlayerManager.currentMusic
            .map { Mutation.setCurrentSong($0) }

        let isPlayingMutation = musicPlayerManager.isNowPlaying
            .map { Mutation.setIsPlaying($0 ?? false) }

        let progressMutation = musicPlayerManager.songProgress
            .map { Mutation.setProgress($0) }

        let songsAvailableMutation = musicPlayerManager.songList
            .map { Mutation.setSongsAvailable(!$0.isEmpty) }

        return Observable.merge(
            mutation,
            currentSongMutation,
            isPlayingMutation,
            progressMutation,
            songsAvailableMutation
        )
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .playPauseTapped:
            musicPlayerManager.togglePlaying()
            return .empty()

        case .previousTapped:
            musicPlayerManager.prev()
            return .empty()

        case .nextTapped:
            musicPlayerManager.next()
            return .empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCurrentSong(let song):
            newState.currentSong = song
        case .setIsPlaying(let isPlaying):
            newState.isPlaying = isPlaying
        case .setProgress(let progress):
            newState.progress = progress
        case .setSongsAvailable(let isAvailable):
            newState.isSongsAvailable = isAvailable
        }
        return newState
    }
}
