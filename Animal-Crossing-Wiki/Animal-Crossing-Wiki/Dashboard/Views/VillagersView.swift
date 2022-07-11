//
//  VillagersView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class VillagersView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private var heightConstraint: NSLayoutConstraint!
    private let longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0.5
        return gesture
    }()
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 50, height: 50)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(IconCell.self)
        return collectionView
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.setTitleColor(.acText, for: .normal)
        button.titleLabel?.font = .preferredFont(for: .footnote, weight: .semibold)
        button.backgroundColor = .acText.withAlphaComponent(0.2)
        button.layer.cornerRadius = 12
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .acText
        label.numberOfLines = 0
        return label
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
        let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height + 80
        self.heightConstraint.constant = contentHeight == .zero ? 80 : contentHeight
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.heightConstraint.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height + 80
    }
    
    private func configure() {
        addSubviews(collectionView, resetButton, descriptionLabel)
        collectionView.addGestureRecognizer(longPressGesture)

        self.heightConstraint = self.collectionView.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            resetButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            resetButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -8),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }
    
    private func bind(to viewModel: VillagersSectionViewModel) {
        let input = VillagersSectionViewModel.Input(
            didSelectItem: collectionView.rx.itemSelected.asObservable(),
            didTapVillagerLongPress: longPressGesture.rx.event
                .map { (longPressGesture: UIGestureRecognizer) -> IndexPath? in
                    guard let collectionView = longPressGesture.view as? UICollectionView else {
                        return nil
                    }
                    if longPressGesture.state == .began,
                       let indexPath = collectionView.indexPathForItem(
                        at: longPressGesture.location(in: collectionView)
                       ) {
                        return indexPath
                    }
                    return nil
                }.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)

        output.villagers
            .bind(
                to: collectionView.rx.items(
                    cellIdentifier: IconCell.className,
                    cellType: IconCell.self
                )
            ) { _, villager, cell in
                cell.setImage(url: villager.iconImage)
            }.disposed(by: disposeBag)
        
        output.villagers
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe(onNext: { owner, villagers in
                owner.layoutIfNeeded()
                if villagers.isEmpty {
                    owner.subviews.compactMap { $0 as? UIButton }.first?.removeFromSuperview()
                    owner.descriptionLabel.centerXAnchor.constraint(equalTo: owner.centerXAnchor).isActive = true
                    owner.descriptionLabel.centerYAnchor.constraint(equalTo: owner.centerYAnchor).isActive = true
                    owner.descriptionLabel.text = """
                    Who have you talked to today?
                    Find the villagers you have visited and tap the home icon on the villager's page to keep track.
                    """
                } else {
                    owner.subviews.forEach { $0.removeFromSuperview() }
                    owner.descriptionLabel.text = "Long press on a villager to see more info about them."
                    owner.configure()
                }
            }).disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                let cell = self.collectionView.cellForItem(at: indexPath) as? IconCell
                cell?.checkMark()
            }).disposed(by: disposeBag)
        
        resetButton.rx.tap
            .subscribe(onNext: { _ in
                let cells = self.collectionView.visibleCells as? [IconCell]
                cells?.forEach { $0.removeCheckMark() }
            }).disposed(by: disposeBag)
    }
}

extension VillagersView {
    convenience init(_ viewModel: VillagersSectionViewModel) {
        self.init(frame: .zero)
        bind(to: viewModel)
    }
}
