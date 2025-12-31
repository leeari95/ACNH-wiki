//
//  TurnipPredictionView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import UIKit

final class TurnipPredictionView: UIView {

    private lazy var patternLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .headline, weight: .bold)
        label.textColor = .acText
        label.numberOfLines = 0
        return label
    }()

    private lazy var probabilityLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .title2, weight: .bold)
        label.textColor = .acHeaderBackground
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .footnote, weight: .regular)
        label.textColor = .acSecondaryText
        label.numberOfLines = 0
        return label
    }()

    private lazy var priceRangeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .subheadline, weight: .medium)
        label.textColor = .acText
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .acHeaderBackground
        progressView.trackTintColor = .acSecondaryBackground
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        backgroundColor = .acBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.acSecondaryBackground.cgColor

        let headerStack = UIStackView(arrangedSubviews: [patternLabel, probabilityLabel])
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [headerStack, progressView, descriptionLabel, priceRangeLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 8

        addSubviews(mainStack)

        NSLayoutConstraint.activate([
            progressView.heightAnchor.constraint(equalToConstant: 8),

            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    func configure(with prediction: TurnipPrediction) {
        patternLabel.text = prediction.pattern.localizedName
        probabilityLabel.text = String(format: "%.0f%%", prediction.probability * 100)
        descriptionLabel.text = prediction.pattern.description
        priceRangeLabel.text = String(
            format: "%@: %d ~ %d Bells".localized,
            "Expected Range".localized,
            prediction.minPrice,
            prediction.maxPrice
        )
        progressView.setProgress(Float(prediction.probability), animated: true)

        // 패턴에 따른 색상 변경
        switch prediction.pattern {
        case .largeSpikePattern:
            progressView.progressTintColor = .systemGreen
        case .smallSpike:
            progressView.progressTintColor = .systemBlue
        case .fluctuating:
            progressView.progressTintColor = .systemOrange
        case .decreasing:
            progressView.progressTintColor = .systemRed
        case .unknown:
            progressView.progressTintColor = .systemGray
        }
    }
}
