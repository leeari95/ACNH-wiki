//
//  MusicPlayerSectionView.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import UIKit
import RxSwift

final class MusicPlayerSectionView: UIView {

    private let disposeBag = DisposeBag()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()

    private lazy var albumCoverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemFill
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        return imageView
    }()

    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()

    private lazy var songTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .body, weight: .semibold)
        label.textColor = .acText
        label.numberOfLines = 1
        label.text = "No song playing".localized
        return label
    }()

    private lazy var artistLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.text = "K.K. Slider"
        return label
    }()

    private lazy var controlsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        return stackView
    }()

    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "backward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return button
    }()

    private lazy var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "forward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return button
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .acHeaderBackground
        progressView.trackTintColor = .tertiarySystemFill
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        return progressView
    }()

    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true

        let label = UILabel()
        label.text = "Tap to start playing K.K. songs".localized
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0

        view.addSubviews(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private func configure() {
        addSubviews(contentView, emptyStateView)
        contentView.addSubviews(backgroundStackView, progressView)

        infoStackView.addArrangedSubviews(songTitleLabel, artistLabel)
        controlsStackView.addArrangedSubviews(previousButton, playPauseButton, nextButton)
        backgroundStackView.addArrangedSubviews(albumCoverImageView, infoStackView, controlsStackView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            backgroundStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            progressView.topAnchor.constraint(equalTo: backgroundStackView.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            emptyStateView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            emptyStateView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func bind(to reactor: MusicPlayerSectionReactor) {
        // Actions
        playPauseButton.rx.tap
            .map { MusicPlayerSectionReactor.Action.playPauseTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        previousButton.rx.tap
            .map { MusicPlayerSectionReactor.Action.previousTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        nextButton.rx.tap
            .map { MusicPlayerSectionReactor.Action.nextTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        let tapGesture = UITapGestureRecognizer()
        emptyStateView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .map { _ in MusicPlayerSectionReactor.Action.playPauseTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // States
        reactor.state
            .map { $0.currentSong }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] song in
                if let song = song {
                    self?.songTitleLabel.text = song.translations.localizedName()
                    self?.albumCoverImageView.setImage(with: song.image ?? "")
                    self?.contentView.isHidden = false
                    self?.emptyStateView.isHidden = true
                } else {
                    self?.songTitleLabel.text = "No song playing".localized
                    self?.albumCoverImageView.image = nil
                    self?.contentView.isHidden = true
                    self?.emptyStateView.isHidden = false
                }
            }).disposed(by: disposeBag)

        reactor.state
            .map { $0.isPlaying }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isPlaying in
                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
                let imageName = isPlaying ? "pause.fill" : "play.fill"
                self?.playPauseButton.setImage(
                    UIImage(systemName: imageName)?.withConfiguration(config),
                    for: .normal
                )
            }).disposed(by: disposeBag)

        reactor.state
            .map { $0.progress }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] progress in
                self?.progressView.setProgress(progress, animated: true)
            }).disposed(by: disposeBag)
    }
}

extension MusicPlayerSectionView {
    convenience init(_ reactor: MusicPlayerSectionReactor) {
        self.init(frame: .zero)
        configure()
        bind(to: reactor)
    }
}
