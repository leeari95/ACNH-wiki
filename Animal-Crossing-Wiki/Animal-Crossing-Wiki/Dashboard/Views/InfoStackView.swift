//
//  InfoStackView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

class InfoStackView: UIStackView {
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .acText
        label.font = .preferredFont(for: .footnote, weight: .bold)
        label.textAlignment = .left
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .acSecondaryText
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .right
        return label
    }()
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
}

extension InfoStackView {
    convenience init(title: String, description: String) {
        self.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    func configure() {
        axis = .horizontal
        alignment = .fill
        distribution = .fill
        spacing = 70
        
        addArrangedSubviews(titleLabel, descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.widthAnchor.constraint(equalToConstant: 160),
            titleLabel.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    func editDescription(_ text: String?) {
        guard text != "" else {
            return
        }
        descriptionLabel.text = text
    }
}
