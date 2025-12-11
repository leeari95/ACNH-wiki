//
//  MaximizePlayerView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/21.
//

import UIKit
import RxSwift

final class MaximizePlayerView: UIView {

    private let disposeBag = DisposeBag()

    private lazy var containerView: UIVisualEffectView = {
        let effectView: UIVisualEffectView
        if #available(iOS 26.0, *) {
            effectView = UIVisualEffectView(effect: UIGlassEffect())
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        }
        effectView.layer.cornerRadius = 32
        effectView.clipsToBounds = true
        return effectView
    }()

    // MARK: - Player Content Views

    private lazy var playerContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubviews(foldingButton, listButton)
        return stackView
    }()

    private lazy var songInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
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
        stackView.spacing = 6
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

    private lazy var controlsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubviews(shuffleButton, previousButton, playButton, nextButton, repeatButton)
        return stackView
    }()

    // MARK: - List Content Views

    private lazy var listContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private lazy var listHeaderStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubviews(backButton, listTitleLabel, UIView())
        return stackView
    }()

    private lazy var listTitleLabel: UILabel = {
        let label = UILabel(
            text: "Playlist".localized,
            font: .preferredFont(for: .headline, weight: .semibold),
            color: .label
        )
        return label
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()

    // MARK: - UI Components

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.widthAnchor.constraint(equalToConstant: 180).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(
            text: "",
            font: .preferredFont(for: .headline, weight: .bold),
            color: .label
        )
        label.textAlignment = .center
        return label
    }()

    private lazy var artistLabel: UILabel = {
        let label = UILabel(
            text: "K.K. Slider",
            font: .preferredFont(for: .subheadline, weight: .medium),
            color: .secondaryLabel
        )
        label.textAlignment = .center
        return label
    }()

    private lazy var durationBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.trackTintColor = .tertiarySystemFill
        progressView.progressTintColor = .acHeaderBackground
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        return progressView
    }()

    private lazy var timeElaspedLabel: UILabel = {
        let label = UILabel(text: "0:00", font: .preferredFont(forTextStyle: .caption2), color: .secondaryLabel)
        label.textAlignment = .left
        return label
    }()

    private lazy var durationLabel: UILabel = {
        let label = UILabel(text: "0:58", font: .preferredFont(forTextStyle: .caption2), color: .secondaryLabel)
        label.textAlignment = .right
        return label
    }()

    lazy var previousButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "backward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "forward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    lazy var shuffleButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "shuffle")?.withConfiguration(config), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()

    lazy var repeatButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "repeat")?.withConfiguration(config), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()

    lazy var listButton: ExpandedTouchButton = {
        let button = ExpandedTouchButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "music.note.list")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    lazy var foldingButton: ExpandedTouchButton = {
        let button = ExpandedTouchButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.down")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    lazy var backButton: ExpandedTouchButton = {
        let button = ExpandedTouchButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        configure()
        bind()
    }

    private func configure() {
        addSubviews(containerView)
        containerView.contentView.addSubviews(playerContentView, listContentView)

        // Player content
        playerContentView.addSubviews(contentStackView)
        contentStackView.addArrangedSubviews(
            headerStackView, coverImageView, songInfoStackView, playTimeStackView, controlsStackView
        )

        // List content
        listContentView.addSubviews(listHeaderStackView, tableView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Player content
            playerContentView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
            playerContentView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
            playerContentView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
            playerContentView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),

            contentStackView.topAnchor.constraint(equalTo: playerContentView.topAnchor, constant: 16),
            contentStackView.bottomAnchor.constraint(equalTo: playerContentView.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: playerContentView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: playerContentView.trailingAnchor, constant: -20),

            headerStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            playTimeStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            controlsStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor, constant: -20),

            // List content
            listContentView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
            listContentView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
            listContentView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
            listContentView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),

            listHeaderStackView.topAnchor.constraint(equalTo: listContentView.topAnchor, constant: 16),
            listHeaderStackView.leadingAnchor.constraint(equalTo: listContentView.leadingAnchor, constant: 20),
            listHeaderStackView.trailingAnchor.constraint(equalTo: listContentView.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: listHeaderStackView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: listContentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: listContentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: listContentView.bottomAnchor, constant: -12)
        ])
    }

    func showPlayerContent() {
        playerContentView.alpha = 1
        listContentView.alpha = 0
        playerContentView.isHidden = false
        listContentView.isHidden = true
    }

    func showListContent() {
        playerContentView.alpha = 0
        listContentView.alpha = 1
        playerContentView.isHidden = true
        listContentView.isHidden = false
    }

    private func bind() {
        MusicPlayerManager.shared.isNowPlaying
            .compactMap { $0 }
            .subscribe(with: self, onNext: { owner, isPlaying in
                let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
                owner.playButton.setImage(
                    UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")?.withConfiguration(config),
                    for: .normal
                )
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.currentMusic
            .compactMap { $0 }
            .subscribe(with: self, onNext: { owner, song in
                owner.coverImageView.kf.cancelDownloadTask()
                owner.titleLabel.text = song.translations.localizedName()
                owner.coverImageView.setImage(with: song.image ?? "")
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.songProgress
            .subscribe(onNext: { [weak self] value in
                self?.durationBar.setProgress(value, animated: false)
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.currentTime
            .subscribe(onNext: { [weak self] value in
                self?.timeElaspedLabel.text = value
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.fullTime
            .filter { [weak self] fullTime in
                self?.durationLabel.text != fullTime
            }
            .subscribe(onNext: { [weak self] value in
                self?.durationLabel.text = value
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.currentPlayerMode
            .subscribe(onNext: { [weak self] playerMode in
                let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
                switch playerMode {
                case .fullRepeat:
                    self?.repeatButton.setImage(UIImage(systemName: "repeat")?.withConfiguration(config), for: .normal)
                    self?.repeatButton.tintColor = .acHeaderBackground
                    self?.shuffleButton.tintColor = .secondaryLabel
                case .oneSongRepeat:
                    self?.repeatButton.setImage(UIImage(systemName: "repeat.1")?.withConfiguration(config), for: .normal)
                    self?.repeatButton.tintColor = .acHeaderBackground
                case .shuffle:
                    self?.shuffleButton.tintColor = .acHeaderBackground
                    self?.repeatButton.tintColor = .secondaryLabel
                }
            }).disposed(by: disposeBag)
    }
}

final class ExpandedTouchButton: UIButton {
    private let expandedTouchInset: CGFloat = -22

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: expandedTouchInset, dy: expandedTouchInset)
        return expandedBounds.contains(point)
    }
}
