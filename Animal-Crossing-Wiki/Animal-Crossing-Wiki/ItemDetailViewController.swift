//
//  ItemDetailViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import UIKit
import RxSwift

class ItemDetailViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView()
    
    private lazy var checkButton: UIButton = {
        let button = UIButton()
        button.tintColor = .acNavigationBarTint
        let config = UIImage.SymbolConfiguration(scale: .large)
        button.setImage(
            UIImage(systemName: "checkmark.seal", withConfiguration: config),
            for: .normal
        )
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        setUpNavigationItem()
        view.backgroundColor = .acBackground
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setUpNavigationItem() {
        let checkBarButton = UIBarButtonItem(customView: checkButton)
        navigationItem.rightBarButtonItems = [checkBarButton]
    }

    func bind(to viewModel: ItemDetailViewModel) {
        let input = ItemDetailViewModel.Input(
            didTapCheck: checkButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.item
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, item in
                owner.navigationItem.title = item.translations.localizedName()
                owner.setUpSection(in: item)
            }).disposed(by: disposeBag)
        
        output.isAcquired
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isAcquired in
                let config = UIImage.SymbolConfiguration(scale: .large)
                owner.checkButton.setImage(
                    UIImage(systemName: isAcquired ? "checkmark.seal.fill" : "checkmark.seal", withConfiguration: config),
                    for: .normal
                )
            }).disposed(by: disposeBag)
    }
    
    private func setUpSection(in item: Item) {
        let itemDetailInfo = SectionView(
            title: item.category.rawValue.localized.uppercased(),
            category: item.category,
            contentView: ItemDetailInfoView(item: item)
        )
        sectionsScrollView.addSection(itemDetailInfo)
        if Category.critters.contains(item.category) {
            let seasonView = SectionView(
                title: "Seasonality".localized,
                iconName: "calendar",
                contentView: ItemSeasonView(item: item)
            )
            sectionsScrollView.addSection(seasonView)
        }
    }
}
