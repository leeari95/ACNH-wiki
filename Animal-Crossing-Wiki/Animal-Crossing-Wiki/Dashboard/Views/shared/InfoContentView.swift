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
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        axis = .horizontal
        alignment = .fill
        distribution = .fill
        spacing = 4
        addArrangedSubviews(titleLabel)
    }
}

extension InfoContentView {
    convenience init(title: String, contentView: UIView...) {
        self.init(frame: .zero)
        self.titleLabel.text = title
        addArrangedSubviews(contentView)
    }
    
    func changeTitleFont(_ font: UIFont) {
        titleLabel.font = font
    }
}
