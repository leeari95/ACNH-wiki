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
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 12
        return stackView
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
        button.setTitle("Reset".localized, for: .normal)
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
    
    private lazy var emptyLabel: UILabel = {
        let text = "vilagerEmpty".localized
        let label = UILabel(text: text, font: .preferredFont(forTextStyle: .footnote), color: .acText)
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubviews(label)
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        return label
    }()
    
    private func updateCollectionViewHeight() {
        let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height
        self.heightConstraint.constant = contentHeight == .zero ? 60 : contentHeight
    }
    
    private func configure() {
        addSubviews(backgroundStackView)
        backgroundStackView.addArrangedSubviews(collectionView, descriptionLabel, resetButton)

        self.heightConstraint = self.collectionView.heightAnchor.constraint(equalToConstant: 60)
        heightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            collectionView.widthAnchor.constraint(equalTo: backgroundStackView.widthAnchor),
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
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe(onNext: { owner, villagers in
                if villagers.isEmpty {
                    owner.emptyLabel.isHidden = false
                    owner.backgroundStackView.isHidden = true
                } else {
                    owner.emptyLabel.isHidden = true
                    owner.backgroundStackView.isHidden = false
                    owner.descriptionLabel.text = "tip".localized
                }
                owner.updateCollectionViewHeight()
                owner.layoutIfNeeded()
            }).disposed(by: disposeBag)
        
        output.villagers
            .bind(
                to: collectionView.rx.items(
                    cellIdentifier: IconCell.className,
                    cellType: IconCell.self
                )
            ) { _, villager, cell in
                cell.setImage(url: villager.iconImage)
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                HapticManager.shared.selection()
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
        configure()
        bind(to: viewModel)
    }
}
