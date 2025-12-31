//
//  CurrentCreaturesView.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import UIKit
import RxSwift

final class CurrentCreaturesView: UIView {

    private let disposeBag = DisposeBag()

    private var heightConstraint: NSLayoutConstraint!

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 12
        return stackView
    }()

    private lazy var filterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    private lazy var allButton: UIButton = createFilterButton(title: "All".localized, tag: 0)
    private lazy var fishButton: UIButton = createFilterButton(title: Category.fishes.rawValue.localized, tag: 1)
    private lazy var bugButton: UIButton = createFilterButton(title: Category.bugs.rawValue.localized, tag: 2)
    private lazy var seaCreatureButton: UIButton = createFilterButton(title: Category.seaCreatures.rawValue.localized, tag: 3)

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

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .acSecondaryText
        label.numberOfLines = 1
        return label
    }()

    private lazy var emptyLabel: UILabel = {
        let text = "currentCreaturesEmpty".localized
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

    private func createFilterButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.acText, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .preferredFont(for: .caption2, weight: .semibold)
        button.backgroundColor = .acText.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.tag = tag
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }

    private func updateFilterButtonAppearance(_ selectedButton: UIButton) {
        [allButton, fishButton, bugButton, seaCreatureButton].forEach { button in
            button.isSelected = button == selectedButton
            button.backgroundColor = button.isSelected
                ? .acHeaderBackground
                : .acText.withAlphaComponent(0.1)
        }
    }

    private func updateCollectionViewHeight() {
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        heightConstraint.constant = contentHeight == .zero ? 60 : contentHeight
    }

    private func configure() {
        addSubviews(backgroundStackView)

        filterStackView.addArrangedSubviews(allButton, fishButton, bugButton, seaCreatureButton)
        backgroundStackView.addArrangedSubviews(filterStackView, collectionView, countLabel)

        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 60)
        heightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            filterStackView.leadingAnchor.constraint(equalTo: backgroundStackView.leadingAnchor),
            filterStackView.trailingAnchor.constraint(equalTo: backgroundStackView.trailingAnchor),
            collectionView.widthAnchor.constraint(equalTo: backgroundStackView.widthAnchor),
            heightConstraint
        ])

        updateFilterButtonAppearance(allButton)
    }

    private func bind(to reactor: CurrentCreaturesSectionReactor) {
        Observable.just(CurrentCreaturesSectionReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Filter button bindings
        allButton.rx.tap
            .do(onNext: { [weak self] in
                self?.updateFilterButtonAppearance(self?.allButton ?? UIButton())
            })
            .map { CurrentCreaturesSectionReactor.Action.filterChanged(category: nil) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        fishButton.rx.tap
            .do(onNext: { [weak self] in
                self?.updateFilterButtonAppearance(self?.fishButton ?? UIButton())
            })
            .map { CurrentCreaturesSectionReactor.Action.filterChanged(category: .fishes) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        bugButton.rx.tap
            .do(onNext: { [weak self] in
                self?.updateFilterButtonAppearance(self?.bugButton ?? UIButton())
            })
            .map { CurrentCreaturesSectionReactor.Action.filterChanged(category: .bugs) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        seaCreatureButton.rx.tap
            .do(onNext: { [weak self] in
                self?.updateFilterButtonAppearance(self?.seaCreatureButton ?? UIButton())
            })
            .map { CurrentCreaturesSectionReactor.Action.filterChanged(category: .seaCreatures) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Collection view binding
        reactor.state
            .map { state -> [Item] in
                if state.selectedCategory == nil {
                    return state.creatures
                } else {
                    return state.filteredCreatures
                }
            }
            .bind(
                to: collectionView.rx.items(
                    cellIdentifier: IconCell.className,
                    cellType: IconCell.self
                )
            ) { _, item, cell in
                cell.setImage(url: item.iconImage ?? "")
            }.disposed(by: disposeBag)

        // Empty state and count label
        reactor.state
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                let creatures = state.selectedCategory == nil ? state.creatures : state.filteredCreatures
                if creatures.isEmpty {
                    self?.emptyLabel.isHidden = false
                    self?.backgroundStackView.isHidden = true
                } else {
                    self?.emptyLabel.isHidden = true
                    self?.backgroundStackView.isHidden = false
                    self?.countLabel.text = String(format: "currentCreaturesCount".localized, creatures.count)
                }
                self?.updateCollectionViewHeight()
                self?.layoutIfNeeded()
            }).disposed(by: disposeBag)

        // Item selection
        collectionView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                HapticManager.shared.selection()
                reactor.action.onNext(.creatureTapped(index: indexPath.item))
            }).disposed(by: disposeBag)
    }
}

extension CurrentCreaturesView {
    convenience init(_ viewModel: CurrentCreaturesSectionReactor) {
        self.init(frame: .zero)
        configure()
        bind(to: viewModel)
    }
}
