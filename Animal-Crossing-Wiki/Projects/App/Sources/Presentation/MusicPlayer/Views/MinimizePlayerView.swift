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

    private lazy var containerView: UIVisualEffectView = {
        let effectView: UIVisualEffectView
        if #available(iOS 26.0, *) {
            effectView = UIVisualEffectView(effect: UIGlassEffect())
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        }
        effectView.clipsToBounds = true
        return effectView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12
        return stackView
    }()

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.widthAnchor.constraint(equalToConstant: 36).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        return imageView
    }()

    private lazy var progressView: CircularProgressView = {
        let view = CircularProgressView()
        view.widthAnchor.constraint(equalToConstant: 44).isActive = true
        view.heightAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        return view
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        return button
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: "forward.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .label
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return button
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark")?.withConfiguration(config), for: .normal)
        button.tintColor = .secondaryLabel
        button.widthAnchor.constraint(equalToConstant: 28).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }()

    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .clear
        configure()
        bind()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }

    private func configure() {
        addSubviews(containerView)
        containerView.contentView.addSubviews(contentStackView)

        progressView.addSubviews(playButton)
        contentStackView.addArrangedSubviews(coverImageView, progressView, nextButton, cancelButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentStackView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 10),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor, constant: -10),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor, constant: -14),

            playButton.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: progressView.centerYAnchor)
        ])
    }

    private func bind() {
        MusicPlayerManager.shared.isNowPlaying
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] isPlaying in
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
                self?.playButton.setImage(
                    UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")?.withConfiguration(config),
                    for: .normal
                )
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.currentMusic
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] song in
                self?.coverImageView.kf.cancelDownloadTask()
                self?.coverImageView.setImage(with: song.image ?? "")
            }).disposed(by: disposeBag)

        MusicPlayerManager.shared.songProgress
            .subscribe(onNext: { [weak self] value in
                self?.progressView.setProgress(value)
            }).disposed(by: disposeBag)
    }
}

private final class CircularProgressView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private var progress: Float = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.tertiarySystemFill.cgColor
        trackLayer.lineWidth = 3
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.acHeaderBackground.cgColor
        progressLayer.lineWidth = 3
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - 3) / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }

    func setProgress(_ progress: Float) {
        self.progress = progress
        progressLayer.strokeEnd = CGFloat(progress)
    }
}
