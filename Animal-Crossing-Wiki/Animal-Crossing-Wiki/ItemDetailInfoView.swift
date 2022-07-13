//
//  ItemDetailInfoView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/06.
//

import UIKit

class ItemDetailInfoView: UIView {
    
    enum ImageSize {
        static let large: CGFloat = 150
        static let medium: CGFloat = 100
    }
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 15
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return stackView
    }()
    
    private lazy var subImageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private lazy var categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()
    
    convenience init(item: Item) {
        self.init(frame: .zero)
        configure(in: item.category, item: item)
    }
    
    private func configure(in category: Category, item: Item) {
        addSubviews(backgroundStackView)
        setUpImageView(item)
        setUpItemBells(item)
        
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func infoStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }
    
    private func setUpImageView(_ item: Item) {
        if Category.critters.contains(item.category) {
            let critterpediaImageView = UIImageView(path: item.critterpediaImage)
            let furnitureImageView = UIImageView(path: item.furnitureImage)
            let iconImageView = UIImageView(path: item.iconImage)
            
            NSLayoutConstraint.activate([
                critterpediaImageView.widthAnchor.constraint(equalToConstant: ImageSize.large),
                critterpediaImageView.heightAnchor.constraint(equalTo: critterpediaImageView.widthAnchor),
                furnitureImageView.widthAnchor.constraint(equalToConstant: ImageSize.medium),
                furnitureImageView.heightAnchor.constraint(equalTo: furnitureImageView.widthAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: ImageSize.medium),
                iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor)
            ])
            subImageStackView.addArrangedSubviews(furnitureImageView, iconImageView)
            backgroundStackView.addArrangedSubviews(critterpediaImageView, subImageStackView)
        } else if let art = item as? Art, let highResTexture = art.highResTexture {
            let highResTextureImageView = UIImageView(path: highResTexture)
            backgroundStackView.addArrangedSubviews(highResTextureImageView)
            NSLayoutConstraint.activate([
                highResTextureImageView.widthAnchor.constraint(equalTo: backgroundStackView.widthAnchor),
                highResTextureImageView.heightAnchor.constraint(equalTo: highResTextureImageView.widthAnchor)
            ])
        } else {
            let imageView = UIImageView(path: item.image)
            imageView.widthAnchor.constraint(equalToConstant: ImageSize.large).isActive = true
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
            backgroundStackView.addArrangedSubviews(imageView)
        }
    }
    
    private func setUpItemBells(_ item: Item) {
        if [Category.seaCreatures, Category.fishes].contains(item.category) {
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            let cjSell = ItemBellsView(mode: .cj, price: Int(Double(item.sell) * 1.5))
            let infoStackView = infoStackView()
            infoStackView.spacing = 16
            infoStackView.addArrangedSubviews(sell, cjSell)
            backgroundStackView.addArrangedSubviews(infoStackView)
        } else if item.category == .bugs {
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            let flickSell = ItemBellsView(mode: .flick, price: Int(Double(item.sell) * 1.5))
            let infoStackView = infoStackView()
            infoStackView.spacing = 16
            infoStackView.addArrangedSubviews(sell, flickSell)
            backgroundStackView.addArrangedSubviews(infoStackView)
        } else if item.buy > 0 {
            let buy = ItemBellsView(mode: .buy, price: item.buy)
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            let infoStackView = infoStackView()
            infoStackView.spacing = 16
            infoStackView.addArrangedSubviews(buy, sell)
            backgroundStackView.addArrangedSubviews(infoStackView)
        } else {
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            backgroundStackView.addArrangedSubviews(sell)
        }
    }
}
