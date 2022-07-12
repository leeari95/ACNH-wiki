//
//  SectionHeaderView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

class SectionHeaderView: UIView {

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        return stackView
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = .init(
            font: .preferredFont(forTextStyle: .subheadline),
            scale: .small
        )
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .acHeaderBackground
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.font = .preferredFont(for: .footnote, weight: .semibold)
        return label
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        addSubviews(backgroundStackView)
        backgroundStackView.addArrangedSubviews(iconImageView, titleLabel)
        backgroundColor = .clear
        layer.cornerRadius = 14
        
        NSLayoutConstraint.activate([
            backgroundStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor, constant: -24)
        ])
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}

extension SectionHeaderView {
    func setUp(title: String, iconName: String) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: iconName)
    }
}
