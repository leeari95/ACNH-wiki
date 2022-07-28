//
//  MaximizePlayerView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/21.
//

import UIKit
import RxSwift

class MaximizePlayerView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var songInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubviews(titleLabel, artistLabel)
        return stackView
    }()
    
    private lazy var playTimeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.addArrangedSubviews(durationBar, songProgressStackView)
        return stackView
    }()
    
    private lazy var songProgressStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.addArrangedSubviews(timeElaspedLabel, durationLabel)
        return stackView
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 40
        stackView.addArrangedSubviews(shuffleButton, previousButton, playButton, nextButton, repeatButton)
        return stackView
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(
            text: "",
            font: .preferredFont(for: .title2, weight: .bold),
            color: .acText
        )
        return label
    }()
    
    private lazy var artistLabel: UILabel = {
        let label = UILabel(
            text: "K.K Slider",
            font: .preferredFont(for: .footnote, weight: .semibold),
            color: .acText.withAlphaComponent(0.5)
        )
        return label
    }()
    
    private lazy var durationBar: ProgressBar = {
        let progressBar = ProgressBar(height: 6)
        progressBar.tintColor = .acHeaderBackground
        return progressBar
    }()
    
    private lazy var timeElaspedLabel: UILabel = {
        let label = UILabel(text: "0:00", font: .preferredFont(forTextStyle: .footnote), color: .acText)
        label.textAlignment = .left
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel(text: "0:58", font: .preferredFont(forTextStyle: .footnote), color: .acText)
        label.textAlignment = .right
        return label
    }()
    
    lazy var previousButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title2, weight: .bold))
        button.setImage(UIImage(systemName: "backward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .largeTitle, weight: .bold))
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title2, weight: .bold))
        button.setImage(UIImage(systemName: "forward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var shuffleButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title3, weight: .semibold))
        button.setImage(UIImage(systemName: "shuffle")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var repeatButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title3, weight: .bold))
        button.setImage(UIImage(systemName: "repeat")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var listButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .largeTitle, weight: .bold))
        button.setImage(UIImage(systemName: "music.note.list")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var foldingButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .largeTitle, weight: .semibold))
        button.setImage(UIImage(systemName: "chevron.compact.down")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        configure()
        bind()
    }
    
    private func configure() {
        addSubviews(backgroundStackView)
        backgroundStackView.addArrangedSubviews(
            foldingButton, coverImageView, songInfoStackView, playTimeStackView, buttonStackView, listButton
        )
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            durationBar.widthAnchor.constraint(equalTo: widthAnchor, constant: -40),
            songProgressStackView.widthAnchor.constraint(equalTo: durationBar.widthAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 37)
        ])
    }
    
    private func bind() {
        MusicPlayerManager.shared.isNowPlaying
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, isPlaying in
                let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .largeTitle, weight: .bold))
                owner.playButton.setImage(
                    UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")?.withConfiguration(config),
                    for: .normal
                )
            }).disposed(by: disposeBag)
        
        MusicPlayerManager.shared.currentMusic
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, song in
                owner.coverImageView.kf.cancelDownloadTask()
                owner.titleLabel.text = song.translations.localizedName()
                owner.coverImageView.setImage(with: song.image ?? "")
            }).disposed(by: disposeBag)
        
        MusicPlayerManager.shared.songProgress
            .withUnretained(self)
            .subscribe(onNext: { owner, value in
                owner.durationBar.setProgress(value, animated: false)
            }).disposed(by: disposeBag)
        
        MusicPlayerManager.shared.currentTime
            .withUnretained(self)
            .subscribe(onNext: { owner, value in
                owner.timeElaspedLabel.text = value
            }).disposed(by: disposeBag)
        
        MusicPlayerManager.shared.fullTime
            .filter { self.durationLabel.text != $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, value in
                owner.durationLabel.text = value
            }).disposed(by: disposeBag)
        
        MusicPlayerManager.shared.currentPlayerMode
            .withUnretained(self)
            .subscribe(onNext: { owner, playerMode in
                let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title3, weight: .semibold))
                switch playerMode {
                case .fullRepeat:
                    owner.repeatButton.setImage(UIImage(systemName: "repeat")?.withConfiguration(config), for: .normal)
                    owner.repeatButton.tintColor = .acHeaderBackground
                    owner.shuffleButton.tintColor = .acText
                case .oneSongRepeat:
                    owner.repeatButton.setImage(UIImage(systemName: "repeat.1")?.withConfiguration(config), for: .normal)
                    owner.repeatButton.tintColor = .acHeaderBackground
                case .shuffle:
                    owner.shuffleButton.tintColor = .acHeaderBackground
                    owner.repeatButton.tintColor = .acText
                }
            }).disposed(by: disposeBag)
    }
}
