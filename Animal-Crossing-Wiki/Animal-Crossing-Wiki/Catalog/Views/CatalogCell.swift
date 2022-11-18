//
//  CatalogCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit
import RxSwift

class CatalogCell: UICollectionViewCell {
    
    private var disposeBag = DisposeBag()
    
    @IBOutlet private weak var backgroundStackView: UIStackView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    
    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))
        button.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        button.backgroundColor = .acSecondaryBackground
        button.layer.cornerRadius = 12
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
        iconImageView.layer.cornerRadius = 12
        contentView.backgroundColor = .acSecondaryBackground
        contentView.layer.cornerRadius = 14
        nameLabel.font = .preferredFont(for: .footnote, weight: .bold)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        nameLabel.text = nil
        nameLabel.textColor = .acText
        disposeBag = DisposeBag()
        backgroundStackView.subviews.compactMap { $0 as? ItemBellsView }.first?.removeFromSuperview()
    }
    
    private func configure() {
        addSubviews(checkButton)
        NSLayoutConstraint.activate([
            checkButton.topAnchor.constraint(equalTo: backgroundStackView.topAnchor),
            checkButton.trailingAnchor.constraint(equalTo: backgroundStackView.trailingAnchor)
        ])
    }
    
    private func setUpIconImage(_ item: Item) {
        if let iconImage = item.iconImage {
            iconImageView.setImage(with: iconImage)
        } else {
            iconImageView.setImage(with: item.image ?? "")
        }
    }
    
    private func bind(reactor: CatalogCellReactor) {
        Observable.just(CatalogCellReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        checkButton.rx.tap
            .map { CatalogCellReactor.Action.check }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)
        
        reactor.state.map { $0.isAcquired }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isAcquired in
                let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))
                owner.checkButton.setImage(
                    UIImage(
                        systemName: isAcquired ? "checkmark.seal.fill" : "checkmark.seal",
                        withConfiguration: config
                    ),
                    for: .normal
                )
            }).disposed(by: disposeBag)
    }
}

extension CatalogCell {
    
    func setUp(_ item: Item) {
        setUpIconImage(item)
        nameLabel.text = item.translations.localizedName()
        bind(reactor: CatalogCellReactor(item: item, category: item.category, state: .init(item: item, category: item.category)))
        var priceView: ItemBellsView
        switch item.category {
        case .bugs, .fishes, .seaCreatures:
            priceView = ItemBellsView(mode: .buy, price: item.sell)
        case .fossils:
            priceView = ItemBellsView(mode: .sell, price: item.sell)
        case .art:
            priceView = ItemBellsView(mode: .buy, price: item.sell)
        case .housewares, .miscellaneous, .wallMounted, .wallpaper,
                .floors, .rugs, .other, .ceilingDecor, .recipes, .songs,
                .photos, .tops, .bottoms, .dressUp, .headwear:
            if item.canExchangeNookMiles, let price = item.exchangePrice {
                priceView = ItemBellsView(mode: .miles, price: price)
            } else if item.canExchangeNookPoints, let price = item.exchangePrice {
                priceView = ItemBellsView(mode: .point, price: price)
            } else if !Category.critters.contains(item.category), let buy = item.buy, buy != -1 {
                priceView = ItemBellsView(mode: .buy, price: buy)
            } else {
                priceView = ItemBellsView(mode: .sell, price: item.sell)
            }
        }
        backgroundStackView.addArrangedSubviews(priceView)
    }
}
