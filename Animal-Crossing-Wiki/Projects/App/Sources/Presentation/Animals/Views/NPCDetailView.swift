//
//  NPCDetailView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit

final class NPCDetailView: UIView {

    private lazy var profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 100
        imageView.layer.borderWidth = 4
        imageView.backgroundColor = .systemGray
        imageView.layer.borderColor = UIColor.acBackground.cgColor
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private func configure() {
        addSubviews(backgroundStackView, profileImage)

        let height = backgroundStackView.heightAnchor.constraint(lessThanOrEqualToConstant: 270)
        height.priority = .required
        NSLayoutConstraint.activate([
            profileImage.widthAnchor.constraint(equalToConstant: 200),
            profileImage.heightAnchor.constraint(equalTo: profileImage.widthAnchor),
            profileImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImage.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            backgroundStackView.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 40),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            height
        ])
    }
}

extension NPCDetailView {

    convenience init(_ npc: NPC) {
        self.init(frame: .zero)
        profileImage.setImage(with: npc.photoImage ?? npc.iconImage)

        let items: [(title: String, value: String)] = [
            ("Gender".localized, npc.gender.rawValue.lowercased().localized.capitalized),
            ("Birthday".localized, npc.birthday),
            ("Specie".localized, npc.species.localized)
        ]

        let contentViews = items.map { item -> InfoContentView in
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .right
            label.text = item.value
            label.textColor = .acSecondaryText
            label.font = .preferredFont(forTextStyle: .callout)
            let infoContentView = InfoContentView(title: item.title, contentView: label)
            infoContentView.changeTitleFont(.preferredFont(for: .body, weight: .semibold))
            return infoContentView
        }
        configure()
        backgroundStackView.addArrangedSubviews(contentViews)
    }
}
