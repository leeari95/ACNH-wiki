//
//  ItemBellsView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit

class ItemBellsView: UIView {
    enum Mode {
        case buy, sell, cj, flick
        
        var iconName: String {
            switch self {
            case .sell: return "icon-bell"
            case .buy: return "icon-bells"
            case .cj: return "cj"
            case .flick: return "flick"
            }
        }
    }
    
    private var mode: Mode = .buy
    private var price: Int = 0
    
    convenience init(mode: Mode, price: Int) {
        self.init(frame: .zero)
        self.mode = mode
        self.price = price
        configure()
    }
    
    private func configure() {
        backgroundColor = .catalogBar
        layer.cornerRadius = 14
        
        let iconImage = UIImageView()
        iconImage.contentMode = .scaleAspectFit
        iconImage.image = UIImage(named: mode.iconName)
        
        let priceLabel = UILabel()
        priceLabel.font = .preferredFont(for: .footnote, weight: .bold)
        priceLabel.textColor = .acTabBarTint
        priceLabel.text = price.decimalFormatted
        
        addSubviews(iconImage, priceLabel)
        
        NSLayoutConstraint.activate([
            iconImage.widthAnchor.constraint(equalToConstant: 25),
            iconImage.heightAnchor.constraint(equalTo: iconImage.widthAnchor),
            iconImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            iconImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            iconImage.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            iconImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            priceLabel.leadingAnchor.constraint(equalTo: iconImage.trailingAnchor, constant: 2),
            priceLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
}
