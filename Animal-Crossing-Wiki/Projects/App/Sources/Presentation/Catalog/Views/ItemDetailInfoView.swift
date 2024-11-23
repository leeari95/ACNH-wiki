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

    private lazy var itemLargeImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
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
        stackView.spacing = 16
        return stackView
    }

    private func setUpImageView(_ item: Item) {
        switch item.category {
        case .bugs, .fishes, .seaCreatures:
            itemLargeImage.setImage(with: item.critterpediaImage ?? "")
            let furnitureImageView = UIImageView(path: item.furnitureImage ?? "")
            let iconImageView = UIImageView(path: item.iconImage ?? "")

            NSLayoutConstraint.activate([
                itemLargeImage.widthAnchor.constraint(equalToConstant: ImageSize.large),
                itemLargeImage.heightAnchor.constraint(equalTo: itemLargeImage.widthAnchor),
                furnitureImageView.widthAnchor.constraint(equalToConstant: ImageSize.medium),
                furnitureImageView.heightAnchor.constraint(equalTo: furnitureImageView.widthAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: ImageSize.medium),
                iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor)
            ])
            subImageStackView.addArrangedSubviews(furnitureImageView, iconImageView)
            backgroundStackView.addArrangedSubviews(itemLargeImage, subImageStackView)
        case .art:
            if let highResTexture = item.highResTexture {
                itemLargeImage.setImage(with: highResTexture)
                backgroundStackView.addArrangedSubviews(itemLargeImage)
                NSLayoutConstraint.activate([
                    itemLargeImage.widthAnchor.constraint(equalTo: backgroundStackView.widthAnchor),
                    itemLargeImage.heightAnchor.constraint(equalTo: itemLargeImage.widthAnchor)
                ])
            } else {
                itemLargeImage.setImage(with: item.image ?? "")
                itemLargeImage.widthAnchor.constraint(equalToConstant: ImageSize.large).isActive = true
                itemLargeImage.heightAnchor.constraint(equalTo: itemLargeImage.widthAnchor).isActive = true
                backgroundStackView.addArrangedSubviews(itemLargeImage)
            }
        default:
            itemLargeImage.setImage(with: item.image ?? "")
            itemLargeImage.widthAnchor.constraint(equalToConstant: ImageSize.large).isActive = true
            itemLargeImage.heightAnchor.constraint(equalTo: itemLargeImage.widthAnchor).isActive = true
            backgroundStackView.addArrangedSubviews(itemLargeImage)
        }
    }

    private func setUpItemBells(_ item: Item) {
        let infoStackView = infoStackView()
        switch item.category {
        case .bugs:
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            let flickSell = ItemBellsView(mode: .flick, price: Int(Double(item.sell) * 1.5))
            infoStackView.addArrangedSubviews(sell, flickSell)
        case .fishes, .seaCreatures:
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            let cjSell = ItemBellsView(mode: .cj, price: Int(Double(item.sell) * 1.5))
            infoStackView.addArrangedSubviews(sell, cjSell)
        case .tools, .housewares, .miscellaneous, .wallMounted, .wallpaper, .floors, .rugs, .ceilingDecor,
                .other, .recipes, .songs, .fencing,
                .photos, .tops, .bottoms, .dressUp, .headwear, .accessories,
                .socks, .shoes, .bags, .umbrellas, .wetSuit:
            if item.canExchangePoki, let price = item.exchangePrice {
                let priceLabel = ItemBellsView(mode: .poki, price: price)
                infoStackView.addArrangedSubviews(priceLabel)
            } else if item.canExchangeNookMiles, let price = item.exchangePrice {
                let price = ItemBellsView(mode: .miles, price: price)
                infoStackView.addArrangedSubviews(price)
            } else if item.canExchangeNookPoints, let price = item.exchangePrice {
                let price = ItemBellsView(mode: .point, price: price)
                infoStackView.addArrangedSubviews(price)
            }
        case .reactions: return
        default: break
        }
        if let buy = item.buy, buy > 0, item.isCritters == false {
            let buy = ItemBellsView(mode: .buy, price: buy)
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            infoStackView.addArrangedSubviews(buy, sell)
        } else if item.isCritters == false {
            let sell = ItemBellsView(mode: .sell, price: item.sell)
            infoStackView.addArrangedSubviews(sell)
        }
        backgroundStackView.addArrangedSubviews(infoStackView)
    }

    func changeImage(_ image: UIImage) {
        itemLargeImage.image = image
    }
}
