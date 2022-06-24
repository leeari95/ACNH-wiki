//
//  VillagersSection.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class VillagersSection: UIView {
    
    private var viewModel: VillagersSectionViewModel?
    private let disposeBag = DisposeBag()
    
    private var heightConstraint: NSLayoutConstraint!
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 50, height: 50)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height
        self.heightConstraint.constant = contentHeight == .zero ? 40 : contentHeight
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.heightConstraint.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    private func configure() {
        collectionView.registerNib(ItemRow.self)
        addSubviews(collectionView)

        self.heightConstraint = self.collectionView.heightAnchor.constraint(equalToConstant: .zero)
        heightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }
    
    private func bind() {
        let input = VillagersSectionViewModel.Input(didSelectItem: collectionView.rx.itemSelected.asObservable())
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)

        output?.villagers
            .bind(
                to: collectionView.rx.items(
                    cellIdentifier: ItemRow.className,
                    cellType: ItemRow.self
                )
            ) { _, villager, cell in
                cell.setImage(url: villager.iconImage)
            }.disposed(by: disposeBag)
        
        output?.villagers
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.layoutIfNeeded()
            }).disposed(by: disposeBag)
    }
}

extension VillagersSection {
    convenience init(_ viewModel: VillagersSectionViewModel) {
        self.init(frame: .zero)
        self.viewModel = viewModel
        bind()
    }
}
