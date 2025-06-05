//
//  EmptyView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/08/01.
//

import UIKit
import ACNHCore
import ACNHShared

final class EmptyView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel(
            text: "",
            font: .preferredFont(for: .body, weight: .semibold),
            color: .acText.withAlphaComponent(0.7)
        )
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel(
            text: "",
            font: .preferredFont(forTextStyle: .footnote),
            color: .acText.withAlphaComponent(0.7)
        )
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView(axis: .vertical, alignment: .center, distribution: .fill, spacing: 8)
        stackView.addArrangedSubviews(titleLabel, descriptionLabel)
        return stackView
    }()

    convenience init(title: String, description: String) {
        self.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description
        configure()
    }

    private func configure() {
        addSubviews(backgroundStackView)

        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func editLabel(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
