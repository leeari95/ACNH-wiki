//
//  CatalogCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit
import RxSwift

class CatalogCell: UICollectionViewCell {
    
    private var viewModel: CatalogCellViewModel!
    private var disposeBag = DisposeBag()
    
    @IBOutlet private weak var backgroundStackView: UIStackView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    
    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))
        button.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
        contentView.backgroundColor = .acSecondaryBackground
        contentView.layer.cornerRadius = 14
        nameLabel.font = .preferredFont(for: .footnote, weight: .bold)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        iconImageView.image = nil
        nameLabel.text = nil
        nameLabel.textColor = .acText
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
    
    private func bind() {
        let input = CatalogCellViewModel.Input(didTapCheck: checkButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.isAcquired
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isAcquired in
                let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))
                if isAcquired {
                    owner.checkButton.setImage(UIImage(systemName: "checkmark.seal.fill", withConfiguration: config), for: .normal)
                } else {
                    owner.checkButton.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
                }
            }).disposed(by: disposeBag)
    }
}

extension CatalogCell {
    
    func setUp(_ item: Item) {
        viewModel = CatalogCellViewModel(item: item, category: item.category)
        bind()
        let sellView = ItemBellsView(mode: .buy, price: item.sell)
        backgroundStackView.addArrangedSubviews(sellView)
        setUpIconImage(item)
        nameLabel.text = item.translations.localizedName()
    }
}
