//
//  MusicPlayerSectionView.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import UIKit
import RxSwift
import Kingfisher

final class MusicPlayerSectionView: UIView {

    private let disposeBag = DisposeBag()
    private let emptyStateTapGesture = UITapGestureRecognizer()

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

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading songs...".localized
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true

        view.addSubviews(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 제스처는 초기에 비활성화하고, 곡 목록이 로드되면 활성화됨
        emptyStateTapGesture.isEnabled = false
        view.addGestureRecognizer(emptyStateTapGesture)

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
            // contentView의 높이(albumCover 60 + spacing 12 + progressView 4 = 76)와 일치시킴
            emptyStateView.heightAnchor.constraint(equalToConstant: 76)
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

        emptyStateTapGesture.rx.event
            .map { _ in MusicPlayerSectionReactor.Action.playPauseTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // States
        reactor.state
            .map { $0.currentSong }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] song in
                // 이전 이미지 다운로드 취소
                self?.albumCoverImageView.kf.cancelDownloadTask()
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
            .scan((previous: Float(0), current: Float(0))) { acc, new in
                (previous: acc.current, current: new)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] progressPair in
                // 곡이 변경되어 progress가 크게 감소할 때는 애니메이션 없이 리셋
                let shouldAnimate = progressPair.current >= progressPair.previous
                self?.progressView.setProgress(progressPair.current, animated: shouldAnimate)
            }).disposed(by: disposeBag)

        reactor.state
            .map { $0.isSongsAvailable }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isAvailable in
                self?.emptyStateTapGesture.isEnabled = isAvailable
                self?.emptyStateLabel.text = isAvailable
                    ? "Tap to start playing K.K. songs".localized
                    : "Loading songs...".localized
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
