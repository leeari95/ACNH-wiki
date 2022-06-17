//
//  PreferencesContentView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit

class PreferencesContentView: UIStackView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.textColor = .black
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

extension PreferencesContentView {
    convenience init(title: String, contentView: UIView...) {
        self.init(frame: .zero)
        self.titleLabel.text = title
        addArrangedSubviews(contentView)
    }
}
