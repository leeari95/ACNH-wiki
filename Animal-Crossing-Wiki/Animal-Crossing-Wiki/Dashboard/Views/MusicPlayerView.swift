//
//  MusicPlayerView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/24.
//

import UIKit
import RxSwift

class MusicPlayerView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 30, left: .zero, bottom: 30, right: .zero)
        return stackView
    }()
    
    private lazy var songStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.addArrangedSubviews(coverImageView, songInfoStackView)
        return stackView
    }()
    
    private lazy var songInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
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
        stackView.spacing = 30
        stackView.addArrangedSubviews(shuffleButton, previousButton, playButton, nextButton, repeatButton)
        return stackView
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.image = UIImage(named: "TodaySong")
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(text: "What is today's song?".localized, font: .preferredFont(forTextStyle: .headline), color: .acText)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var artistLabel: UILabel = {
        let label = UILabel(
            text: "Click the play button.".localized,
            font: .preferredFont(for: .footnote, weight: .semibold),
            color: .acText.withAlphaComponent(0.5)
        )
        return label
    }()
    
    private lazy var durationBar: ProgressBar = {
        let progressBar = ProgressBar(height: 3)
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
        let label = UILabel(text: "0:00", font: .preferredFont(forTextStyle: .footnote), color: .acText)
        label.textAlignment = .right
        return label
    }()
    
    lazy var previousButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title3, weight: .bold))
        button.setImage(UIImage(systemName: "backward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title1, weight: .bold))
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .title3, weight: .bold))
        button.setImage(UIImage(systemName: "forward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var shuffleButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .body, weight: .semibold))
        button.setImage(UIImage(systemName: "shuffle")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    lazy var repeatButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .body, weight: .bold))
        button.setImage(UIImage(systemName: "repeat")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    convenience init(viewModel: MusicPlayerViewModel) {
        self.init(frame: .zero)
        backgroundColor = .clear
        configure()
        bind(to: viewModel)
    }
    
    private func configure() {
        addSubviews(backgroundStackView)
        backgroundStackView.addArrangedSubviews(
            songStackView, playTimeStackView, buttonStackView
        )
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            songStackView.widthAnchor.constraint(equalTo: backgroundStackView.widthAnchor, constant: -20),
            durationBar.widthAnchor.constraint(equalTo: widthAnchor, constant: -20),
            songProgressStackView.widthAnchor.constraint(equalTo: durationBar.widthAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 37)
        ])
    }
    
    private func bind(to viewModel: MusicPlayerViewModel) {
        let input = MusicPlayerViewModel.Input(
            didTapPlayButton: playButton.rx.tap.asObservable(),
            didTapNextButton: nextButton.rx.tap.asObservable(),
            didTapPrevButton: previousButton.rx.tap.asObservable(),
            didTapShuffle: shuffleButton.rx.tap.asObservable(),
            didTapRepeat: repeatButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        output.isPlaying
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, isPlaying in
                let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .largeTitle, weight: .bold))
                owner.playButton.setImage(
                    UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")?.withConfiguration(config),
                    for: .normal
                )
            }).disposed(by: disposeBag)
        
        output.currentSong
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, song in
                if owner.artistLabel.text != "K.K Slider" {
                    owner.artistLabel.text = "K.K Slider"
                }
                owner.titleLabel.text = song.translations.localizedName()
                owner.coverImageView.setImage(with: song.image ?? "")
            }).disposed(by: disposeBag)
        
        output.songProgress
            .withUnretained(self)
            .subscribe(onNext: { owner, value in
                owner.durationBar.setProgress(value, animated: false)
            }).disposed(by: disposeBag)
        
        output.currentTime
            .withUnretained(self)
            .subscribe(onNext: { owner, value in
                owner.timeElaspedLabel.text = value
            }).disposed(by: disposeBag)
        
        output.fullTime
            .filter { self.durationLabel.text != $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, value in
                owner.durationLabel.text = value
            }).disposed(by: disposeBag)
    }
}
