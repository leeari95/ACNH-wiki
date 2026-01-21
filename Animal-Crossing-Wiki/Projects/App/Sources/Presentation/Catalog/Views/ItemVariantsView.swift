//
//  ItemVariantsView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import RxSwift
import RxRelay

final class ItemVariantsView: UIView {

    enum Mode {
        case color
        case pattern
    }

    private let disposeBag = DisposeBag()
    private var mode: Mode = .color
    private let cellImage = BehaviorRelay<UIImage?>(value: nil)
    private let variantChecked = BehaviorRelay<(variantId: String, isChecked: Bool)?>(value: nil)
    
    private var variations: [Variant] = []
    private var checkedVariants: Set<String> = []

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 90, height: 110)
        flowLayout.minimumLineSpacing = 5
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(VariantCell.self)
        return collectionView
    }()

    convenience init(item: [Variant], mode: Mode, checkedVariants: Set<String> = []) {
        self.init(frame: .zero)
        self.mode = mode
        self.variations = item
        self.checkedVariants = checkedVariants
        configure()
        setUpItems()
    }

    private func configure() {
        addSubviews(collectionView)

        let heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 110)
        heightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            heightConstraint
        ])
    }

    private func setUpItems() {
        Observable.just(variations)
            .bind(to: collectionView.rx.items(cellIdentifier: VariantCell.className, cellType: VariantCell.self)
            ) { [weak self] _, item, cell in
                guard let self = self else { return }
                
                let name = (self.mode == .color ? item.variantTranslations?.localizedName() : item.patternTranslations?.localizedName())
                ?? item.variation?.localized
                
                let uniqueId = item.filename
                let isChecked = self.checkedVariants.contains(uniqueId)
                
                cell.setUp(
                    imageURL: item.image,
                    name: name,
                    isChecked: isChecked
                ) { [weak self] in
                    self?.toggleVariantCheck(uniqueId)
                }
            }.disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                let cell = self?.collectionView.cellForItem(at: indexPath) as? VariantCell
                self?.cellImage.accept(cell?.imageView.image)
            }).disposed(by: disposeBag)
    }
    
    private func toggleVariantCheck(_ variantId: String) {
        let isCurrentlyChecked = checkedVariants.contains(variantId)
        variantChecked.accept((variantId: variantId, isChecked: !isCurrentlyChecked))
    }
    
    func updateCheckedVariants(_ checkedVariants: Set<String>) {
        self.checkedVariants = checkedVariants
        collectionView.reloadData()
    }
}

extension ItemVariantsView {

    var didTapImage: Observable<UIImage?> {
        return cellImage.asObservable()
    }
    
    var didCheckVariant: Observable<(variantId: String, isChecked: Bool)> {
        return variantChecked
            .compactMap { $0 }
            .asObservable()
    }
}
