//
//  NpcsView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2024/12/06.
//

import UIKit
import RxSwift

final class NpcsView: UIView {

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
        collectionView.addGestureRecognizer(longPressGesture)
        return collectionView
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("reset".localized, for: .normal)
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
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        heightConstraint.constant = contentHeight == .zero ? 60 : contentHeight
    }

    private func configure() {
        addSubviews(backgroundStackView)
        backgroundStackView.addArrangedSubviews(collectionView, descriptionLabel, resetButton)

        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 60)
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

    private func bind(to reactor: NpcsSectionReactor) {
        Observable.just(NpcsSectionReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        longPressGesture.rx.event
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
            }.compactMap { $0 }
            .map { NpcsSectionReactor.Action.npcLongPress(index: $0.item)}
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state
            .map { state -> [(NPC, Bool)] in
                let checkedNames = Set(state.checkedNpcs.map { $0.name })
                return state.npcs.map { ($0, checkedNames.contains($0.name)) }
            }
            .bind(
                to: collectionView.rx.items(
                    cellIdentifier: IconCell.className,
                    cellType: IconCell.self
                )
            ) { _, npcInfo, cell in
                let (npc, isChecked) = npcInfo
                cell.setImage(url: npc.iconImage)
                cell.setChecked(isChecked)
            }.disposed(by: disposeBag)

        reactor.state
            .map { $0.npcs }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] npcs in
                if npcs.isEmpty {
                    self?.emptyLabel.isHidden = false
                    self?.backgroundStackView.isHidden = true
                } else {
                    self?.emptyLabel.isHidden = true
                    self?.backgroundStackView.isHidden = false
                    self?.descriptionLabel.text = "tip".localized
                }
                self?.updateCollectionViewHeight()
                self?.layoutIfNeeded()
            }).disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                HapticManager.shared.selection()
                reactor.action.onNext(.npcChecked(index: indexPath.item))
            }).disposed(by: disposeBag)

        resetButton.rx.tap
            .subscribe(onNext: { _ in
                reactor.action.onNext(.resetCheckedNpcs)
            }).disposed(by: disposeBag)
    }
}

extension NpcsView {
    convenience init(_ viewModel: NpcsSectionReactor) {
        self.init(frame: .zero)
        configure()
        bind(to: viewModel)
    }
}
