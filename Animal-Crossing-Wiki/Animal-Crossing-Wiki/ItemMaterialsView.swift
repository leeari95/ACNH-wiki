//
//  ItemMaterialsView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/20.
//

import UIKit

class ItemMaterialsView: UIView {
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 15
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 10)
        return stackView
    }()
    
    convenience init(item: Item) {
        self.init(frame: .zero)
        configure(in: item)
    }
    
    private func configure(in item: Item) {
        addSubviews(backgroundStackView)
        setUpMaterials(item)
        
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
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
    
    private func setUpMaterials(_ item: Item) {
        let materials = item.recipe?.materials
        materials?.forEach({ material, count in
            let materialsItem = Items.shared.materialsItemList[material]
            let countLabel = descriptionLabel(count.description)
            materialsItem.flatMap {
                let infoView = InfoContentView(item: $0, contentView: countLabel)
                backgroundStackView.addArrangedSubviews(infoView)
            }
        })
    }
    
}
