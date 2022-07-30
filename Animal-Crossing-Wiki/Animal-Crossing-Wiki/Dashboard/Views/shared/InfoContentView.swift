//
//  PreferencesContentView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit

class InfoContentView: UIStackView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .callout, weight: .medium)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textColor = .acText
        return label
    }()
    
    private func configure() {
        axis = .horizontal
        alignment = .fill
        distribution = .fill
        spacing = 8
    }
}

extension InfoContentView {
    convenience init(title: String, contentView: UIView...) {
        self.init(frame: .zero)
        configure()
        self.titleLabel.text = title
        addArrangedSubviews(titleLabel)
        addArrangedSubviews(contentView)
    }
    
    convenience init(item: Item, contentView: UIView...) {
        self.init(frame: .zero)
        configure()
        titleLabel.text = item.translations.localizedName()
        let icon = UIImageView(path: item.image ?? item.iconImage ?? "")
        icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
        icon.heightAnchor.constraint(equalTo: icon.widthAnchor).isActive = true
        addArrangedSubviews(icon, titleLabel)
        addArrangedSubviews(contentView)
    }
    
    func changeTitleFont(_ font: UIFont) {
        titleLabel.font = font
    }
}
