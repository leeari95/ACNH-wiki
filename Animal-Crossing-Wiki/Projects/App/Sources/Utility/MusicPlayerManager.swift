//
//  MusicPlayerManager.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/22.
//

import Foundation
import OSLog
import RxSwift
import RxRelay
import AVFoundation
import MediaPlayer

final class MusicPlayerManager {

    enum PlayerMode {
        case shuffle
        case fullRepeat
        case oneSongRepeat
    }

    static let shared = MusicPlayerManager()

    private let disposeBag = DisposeBag()
    private var player: AVPlayer?
    private var timer: Timer?

    private let isPlaying = BehaviorRelay<Bool?>(value: nil)
    private let currentSong = BehaviorRelay<Item?>(value: nil)
    private var songs = BehaviorRelay<[String: Item]>(value: [:])
    private var songsItem = BehaviorRelay<[Item]>(value: [])
    private let playerMode = BehaviorRelay<PlayerMode>(value: .fullRepeat)

    private let playerProgress = BehaviorRelay<Float>(value: 0)
    private let durationTime = BehaviorRelay<String>(value: "0:00")
    private let elapsedTime = BehaviorRelay<String>(value: "0:00")
    private let currentIndex = BehaviorRelay<Int?>(value: nil)

    private init() {
        Items.shared.categoryList
            .compactMap { $0[.songs] }
            .withUnretained(self)
            .subscribe(onNext: { owner, songs in
                var newSongs = [String: Item]()
                songs.forEach { item in
                    newSongs[item.name] = item
                }
                owner.songs.accept(newSongs)
                owner.songsItem.accept(songs.shuffled())
            }).disposed(by: disposeBag)

        currentSong
            .compactMap { $0?.musicURL }
            .compactMap { URL(string: $0) }
            .withUnretained(self)
            .subscribe(onNext: { owner, musicURL in
                owner.player = AVPlayer(url: musicURL)
            }).disposed(by: disposeBag)

        currentSong
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, song in
                owner.currentIndex.accept(owner.songsItem.value.firstIndex(of: song))
            }).disposed(by: disposeBag)

        isPlaying
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, isPlaying in
                if isPlaying {
                    if owner.currentSong.value == nil {
                        owner.currentSong.accept(owner.songsItem.value.first)
                    }
                    owner.setUpBackground()
                    owner.player?.play()
                } else {
                    owner.player?.pause()
                }
                owner.setUpPlayerTimer()
            }).disposed(by: disposeBag)

        setUpNotification()
        setupRemoteCommands()
    }

    private func changeSong(at newIndex: Int) {
        playerProgress.accept(0)
        elapsedTime.accept("0:00")
        guard let current = currentSong.value,
              var index = songsItem.value.firstIndex(of: current) else {
            os_log(.error, log: .default, "⛔️ 음악을 가져오는데 실패했습니다.")
            return
        }
        index += newIndex
        if let newSong = songsItem.value[safe: index] {
            currentSong.accept(newSong)
        } else if index < 0 {
            let newSong = songsItem.value.last
            currentSong.accept(newSong)
        } else {
            let newSong = songsItem.value.first
            currentSong.accept(newSong)
        }
        isPlaying.accept(true)
    }

    private func updatePlayingInfo() {
        if let duration = player?.currentItem?.duration.seconds,
            let playTime = player?.currentItem?.currentTime().seconds,
            !duration.isNaN, !playTime.isNaN {
            playerProgress.accept(Float(playTime) / Float(duration))

            let durationSecs = Int(duration)
            let durationSeconds = Int(durationSecs % 3600 ) % 60
            let durationMinutes = Int(durationSecs % 3600) / 60
            let durationTime = "\(durationMinutes):\(String(format: "%02d", durationSeconds))"
            self.durationTime.accept(durationTime)

            let playTimeSecs = Int(playTime)
            let playTimeSeconds = Int(playTimeSecs % 3600) % 60
            let playTimeMinutes = Int(playTimeSecs % 3600) / 60
            let elapsedTime = "\(playTimeMinutes):\(String(format: "%02d", playTimeSeconds))"
            self.elapsedTime.accept(elapsedTime)

            setUpRemotePlayingInfo(duration: duration, playTime: playTime)
        }
    }

    private func setUpPlayerTimer() {
        if isPlaying.value == true {
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            timer = Timer.scheduledTimer(
                withTimeInterval: 0.5,
                repeats: true,
                block: { [weak self] _ in
                    self?.updatePlayingInfo()
                }
            )
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func setUpNotification() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self.flatMap { owner in
                owner.playerProgress.accept(0)
                owner.elapsedTime.accept("0:00")
                owner.isPlaying.accept(false)
                switch owner.playerMode.value {
                case .fullRepeat:
                    owner.next()
                case .shuffle:
                    owner.currentSong.accept(owner.songsItem.value.randomElement())
                    owner.isPlaying.accept(true)
                case .oneSongRepeat:
                    owner.currentSong.accept(owner.currentSong.value)
                    owner.isPlaying.accept(true)
                }
            }
        }
    }

    private func setUpBackground() {
        if let currentSong = currentSong.value {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true, options: [])

            var playingInfo: [String: Any] = [:]
            playingInfo[MPMediaItemPropertyArtist] = "K.K. Slider"
            playingInfo[MPMediaItemPropertyAlbumTitle] = "K.K. Slider"
            playingInfo[MPMediaItemPropertyTitle] = currentSong.translations.localizedName()

            UIImage.downloadImage(urlString: currentSong.image ?? "")
                .compactMap { $0 }
                .subscribe(onNext: { image in
                    playingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                        boundsSize: CGSize(width: 100, height: 100), requestHandler: { _ in
                            image
                        }
                    )
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = playingInfo
                }).disposed(by: disposeBag)
        }
    }

    private func setupRemoteCommands() {
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
            if self?.isPlaying.value == false {
                self?.isPlaying.accept(true)
                return .success
            }
            return .commandFailed
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            if self?.isPlaying.value == true {
                self?.isPlaying.accept(false)
                return .success
            }
            return .commandFailed
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { [weak self] _ in
            self?.prev()
            return .success
        }
    }

    private func setUpRemotePlayingInfo(duration: Double, playTime: Double) {
        var playingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        playingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
        playingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = playingInfo
    }

}

extension MusicPlayerManager {

    var isNowPlaying: Observable<Bool?> {
        return isPlaying.asObservable()
    }

    var currentMusic: Observable<Item?> {
        return currentSong.asObservable()
    }

    var currentTime: Observable<String> {
        return elapsedTime.asObservable()
    }

    var fullTime: Observable<String> {
        return durationTime.asObservable()
    }

    var songProgress: Observable<Float> {
        return playerProgress.asObservable()
    }

    var songList: Observable<[Item]> {
        return songsItem.asObservable()
    }

    var playingSongIndex: Observable<Int?> {
        return currentIndex.asObservable()
    }

    var currentPlayerMode: Observable<PlayerMode> {
        return playerMode.asObservable()
    }

    func togglePlaying() {
        isPlaying.accept(isPlaying.value == true ? false : true)
    }

    func updatePlayerMode(to mode: PlayerMode) {
        switch mode {
        case .shuffle:
            playerMode.accept(playerMode.value == .shuffle ? .fullRepeat : .shuffle)
        case .fullRepeat, .oneSongRepeat:
            if playerMode.value == .oneSongRepeat || playerMode.value == .shuffle {
                playerMode.accept(.fullRepeat)
            } else {
                playerMode.accept(.oneSongRepeat)
            }
        }
    }

    func next() {
        changeSong(at: 1)
    }

    func prev() {
        changeSong(at: -1)
    }

    func choice(_ item: Item) {
        close()
        currentSong.accept(item)
        isPlaying.accept(true)
        setUpNotification()
    }

    func close() {
        player = nil
        isPlaying.accept(false)
        elapsedTime.accept("0:00")
        durationTime.accept("0:00")
        playerProgress.accept(0)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
}
