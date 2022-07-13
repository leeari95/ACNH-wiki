//
//  ItemOtherInfoView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/13.
//

import UIKit

class ItemOtherInfoView: UIView {
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 15
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return stackView
    }()
    
    convenience init(item: Item) {
        self.init(frame: .zero)
        configure(in: item)
    }
    
    private func configure(in item: Item) {
        addSubviews(backgroundStackView)
        setUpLabel(item)
        
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func setUpLabel(_ item: Item) {
        let whereHowLabel = descriptionLabel("")
        if item.whereHow != "" {
            whereHowLabel.text = item.whereHow.localized
        } else if item.source != "" {
            whereHowLabel.text = item.source.localized
        } else if item.category == .seaCreatures {
            whereHowLabel.text = "Underwater".localized
        }
        let placeInfo = InfoContentView(title: "Where how".localized, contentView: whereHowLabel)
        backgroundStackView.addArrangedSubviews(placeInfo)
        
        if [Category.fishes, Category.seaCreatures].contains(item.category) {
            let shadowLabel = descriptionLabel(item.shadow.rawValue.localized)
            let shadowInfo = InfoContentView(title: "Shadow size".localized, contentView: shadowLabel)
            backgroundStackView.addArrangedSubviews(shadowInfo)
        }
        
        if item.category == .seaCreatures {
            let speedLabel = descriptionLabel(item.movementSpeed.rawValue.localized)
            let speedInfo = InfoContentView(title: "Movement speed".localized, contentView: speedLabel)
            backgroundStackView.addArrangedSubviews(speedInfo)
        }
        if item.category == .art {
            let fakeInfoLabel = descriptionLabel(item.genuine ? "Original".localized : "Fake".localized)
            let akeInfo = InfoContentView(title: "Whether fake".localized, contentView: fakeInfoLabel)
            backgroundStackView.addArrangedSubviews(akeInfo)
        }
    }
    
    private func descriptionLabel(_ text: String) -> UILabel {
        let label = UILabel(
            text: text,
            font: .preferredFont(for: .callout, weight: .semibold),
            color: .acSecondaryText
        )
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }
    
}
