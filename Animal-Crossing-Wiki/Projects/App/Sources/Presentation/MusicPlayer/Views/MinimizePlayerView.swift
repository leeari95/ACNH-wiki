//
//  MinimizePlayerView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/21.
//

import UIKit
import RxSwift

final class MinimizePlayerView: UIView {

    private let disposeBag = DisposeBag()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 15
        return stackView
    }()

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(text: "", font: .preferredFont(forTextStyle: .headline), color: .acText)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var durationBar: ProgressBar = {
        let progressBar = ProgressBar(height: 3)
        progressBar.tintColor = .acHeaderBackground
        return progressBar
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(forTextStyle: .body))
        button.setImage(UIImage(systemName: "xmark")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        button.setContentHuggingPriority(.init(251), for: .horizontal)
        return button
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(scale: .large)
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        button.setContentHuggingPriority(.init(253), for: .horizontal)
        return button
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(scale: .large)
        button.setImage(UIImage(systemName: "forward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        button.setContentHuggingPriority(.init(252), for: .horizontal)
        return button
    }()

    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        configure()
        bind()
    }

    private func configure() {
        addSubviews(backgroundStackView, durationBar)
        backgroundStackView.addArrangedSubviews(coverImageView, titleLabel, playButton, nextButton, cancelButton)

        let width = UIScreen.main.bounds.width

        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor),
            durationBar.widthAnchor.constraint(equalToConstant: width),
            durationBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            durationBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -20)
        ])
    }

    private func bind() {
        MusicPlayerManager.shared.isNowPlaying
            .compactMap { $0 }
            .subscribe(onNext: { [weak self]  isPlaying in
                let config = UIImage.SymbolConfiguration(scale: .large)
                self?.playButton.setImage(
                    UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")?.withConfiguration(config),
                    for: .normal
                )
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.currentMusic
            .compactMap { $0 }
            .subscribe(onNext: { [weak self]  song in
                self?.coverImageView.kf.cancelDownloadTask()
                self?.titleLabel.text = song.translations.localizedName()
                self?.coverImageView.setImage(with: song.image ?? "")
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.songProgress
            .subscribe(onNext: { [weak self]  value in
                self?.durationBar.setProgress(value, animated: false)
            }).disposed(by: disposeBag)
    }
}
