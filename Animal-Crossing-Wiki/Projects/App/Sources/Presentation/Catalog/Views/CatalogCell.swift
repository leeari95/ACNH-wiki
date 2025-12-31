//
//  CatalogCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit
import RxSwift

final class CatalogCell: UICollectionViewCell {

    private var disposeBag = DisposeBag()
    private var itemName: String?
    private var isItemAcquired: Bool = false

    @IBOutlet private weak var backgroundStackView: UIStackView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let config = UIImage.SymbolConfiguration(font: font)
        button.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        button.backgroundColor = .acSecondaryBackground
        button.layer.cornerRadius = font.pointSize / 2
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
        iconImageView.layer.cornerRadius = 12
        contentView.backgroundColor = .acSecondaryBackground
        contentView.layer.cornerRadius = 14
        nameLabel.font = .preferredFont(for: .footnote, weight: .bold)
        nameLabel.adjustsFontForContentSizeCategory = true
        setupAccessibility()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        checkButton.isAccessibilityElement = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        nameLabel.text = nil
        nameLabel.textColor = .acText
        disposeBag = DisposeBag()
        backgroundStackView.subviews.compactMap { $0 as? ItemBellsView }.first?.removeFromSuperview()
        checkButton.setImage(
            UIImage(
                systemName: "checkmark.seal",
                withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title2))
            ),
            for: .normal
        )
        itemName = nil
        isItemAcquired = false
        updateAccessibilityLabel()
    }

    private func updateAccessibilityLabel() {
        guard let name = itemName else {
            accessibilityLabel = nil
            accessibilityHint = nil
            return
        }
        let acquiredStatus = isItemAcquired ? "acquired".localized : "not_acquired".localized
        accessibilityLabel = "\(name), \(acquiredStatus)"
        accessibilityHint = "double_tap_to_toggle_acquisition".localized
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
            .subscribe(onNext: { [weak self] isAcquired in
                guard let self = self else { return }
                let previousState = self.isItemAcquired
                self.isItemAcquired = isAcquired
                self.updateAccessibilityLabel()

                let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title2))
                self.checkButton.setImage(
                    UIImage(
                        systemName: isAcquired ? "checkmark.seal.fill" : "checkmark.seal",
                        withConfiguration: config
                    ),
                    for: .normal
                )

                // 체크 상태 변경 시 접근성 알림
                if previousState != isAcquired {
                    let announcement = isAcquired ? "item_acquired".localized : "item_not_acquired".localized
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
            }).disposed(by: disposeBag)
    }
}

extension CatalogCell {

    func setUp(_ item: Item) {
        setUpIconImage(item)
        let localizedName = item.translations.localizedName()
        nameLabel.text = localizedName
        itemName = localizedName
        updateAccessibilityLabel()
        bind(reactor: CatalogCellReactor(item: item, category: item.category, state: .init(item: item, category: item.category)))
        var priceView: ItemBellsView
        switch item.category {
        case .bugs, .fishes, .seaCreatures:
            priceView = ItemBellsView(mode: .buy, price: item.sell)
        case .fossils:
            priceView = ItemBellsView(mode: .sell, price: item.sell)
        case .art:
            priceView = ItemBellsView(mode: .buy, price: item.sell)
        case .tools, .housewares, .miscellaneous, .wallMounted, .wallpaper, .fencing,
                .floors, .rugs, .other, .ceilingDecor, .recipes, .songs,
                .photos, .tops, .bottoms, .dressUp, .headwear, .accessories,
                .socks, .shoes, .bags, .umbrellas, .wetSuit, .gyroids:
            if item.canExchangeNookMiles, let price = item.exchangePrice {
                priceView = ItemBellsView(mode: .miles, price: price)
            } else if item.canExchangeNookPoints, let price = item.exchangePrice {
                priceView = ItemBellsView(mode: .point, price: price)
            } else if !Category.critters.contains(item.category), let buy = item.buy, buy != -1 {
                priceView = ItemBellsView(mode: .buy, price: buy)
            } else {
                priceView = ItemBellsView(mode: .sell, price: item.sell)
            }
        default: return
        }
        backgroundStackView.addArrangedSubviews(priceView)
    }
}
