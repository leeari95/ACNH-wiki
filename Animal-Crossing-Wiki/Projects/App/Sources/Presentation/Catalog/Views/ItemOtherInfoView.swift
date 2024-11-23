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
        setUpWhereHow(item)
        setUpShadowSize(item)
        setUpMovementSpeed(item)
        setUpWhetherFake(item)
        item.sourceNotes.flatMap { sourceNotes in
            let sourceNotesLabel = descriptionLabel(sourceNotes.reduce(with: "\n", characters: ["\n"]))
            sourceNotesLabel.numberOfLines = 0
            let sourceNoteInfo = InfoContentView(title: "Source Note".localized, contentView: sourceNotesLabel)
            backgroundStackView.addArrangedSubviews(sourceNoteInfo)
        }
        item.catalog.flatMap { catalog in
            let catalogLabel = descriptionLabel(catalog.rawValue.localized)
            let catalogInfo = InfoContentView(title: "Whether to buy".localized, contentView: catalogLabel)
            backgroundStackView.addArrangedSubviews(catalogInfo)
        }
        if let hhaBasePoint = item.hhaBasePoints, hhaBasePoint > 0 {
            let hhaPointLabel = descriptionLabel(hhaBasePoint.decimalFormatted)
            let hhaPointInfo = InfoContentView(title: "HHA points".localized, contentView: hhaPointLabel)
            backgroundStackView.addArrangedSubviews(hhaPointInfo)
        }
        if let sourceRecipe = item.recipe?.source, item.diy == true {
            let sourceRecipeLabel = descriptionLabel(sourceRecipe.reduce(with: "\n", characters: ["\n"]))
            sourceRecipeLabel.numberOfLines = 0
            let sourceRecipeInfo = InfoContentView(title: "Source recipe".localized, contentView: sourceRecipeLabel)
            backgroundStackView.addArrangedSubviews(sourceRecipeInfo)
        }
    }

    private func descriptionLabel(_ text: String?) -> UILabel {
        let label = UILabel(
            text: text,
            font: .preferredFont(for: .callout, weight: .semibold),
            color: .acSecondaryText
        )
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }

    private func setUpWhereHow(_ item: Item) {
        let whereHowLabel = descriptionLabel("")
        switch item.category {
        case .bugs, .fishes:
            whereHowLabel.text = item.whereHow?.localized
        case .seaCreatures:
            whereHowLabel.text = "Underwater".localized
        case .fossils, .art:
            whereHowLabel.text = item.source?.localized
        case .housewares, .miscellaneous, .wallMounted, .ceilingDecor,
                .wallpaper, .floors, .rugs, .other, .recipes, .songs, .fencing,
                .photos, .tops, .bottoms, .dressUp, .headwear, .accessories,
                .socks, .shoes, .bags, .umbrellas, .wetSuit, .reactions, .gyroids:
            whereHowLabel.text = item.sources?.reduce(with: "\n", characters: ["\n"])

        default: return
        }
        let placeInfo = InfoContentView(title: "Where how".localized, contentView: whereHowLabel)
        backgroundStackView.addArrangedSubviews(placeInfo)
    }

    private func setUpShadowSize(_ item: Item) {
        guard [Category.fishes, Category.seaCreatures].contains(item.category) else {
            return
        }
        let shadowLabel = descriptionLabel(item.shadow?.rawValue.localized)
        let shadowInfo = InfoContentView(title: "Shadow size".localized, contentView: shadowLabel)
        backgroundStackView.addArrangedSubviews(shadowInfo)

    }

    private func setUpMovementSpeed(_ item: Item) {
        guard item.category == .seaCreatures else {
            return
        }
        let speedLabel = descriptionLabel(item.movementSpeed?.rawValue.localized)
        let speedInfo = InfoContentView(title: "Movement speed".localized, contentView: speedLabel)
        backgroundStackView.addArrangedSubviews(speedInfo)
    }

    private func setUpWhetherFake(_ item: Item) {
        guard item.category == .art, let genuine = item.genuine else {
            return
        }
        let fakeInfoLabel = descriptionLabel(genuine ? "Original".localized : "Fake".localized)
        let fakeInfo = InfoContentView(title: "Whether fake".localized, contentView: fakeInfoLabel)
        backgroundStackView.addArrangedSubviews(fakeInfo)
        
        if let fakeDifferences = item.fakeDifferences {
            let fakeDetailLabel = descriptionLabel(fakeDifferences.localizedName())
            let fakeDetail = InfoContentView(title: "differences".localized, contentView: fakeDetailLabel)
            backgroundStackView.addArrangedSubviews(fakeDetail)
        }
    }
}
