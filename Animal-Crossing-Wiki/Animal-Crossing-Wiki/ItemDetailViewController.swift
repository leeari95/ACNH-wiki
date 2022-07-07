//
//  ItemDetailViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import UIKit
import RxSwift

class ItemDetailViewController: UIViewController {
    
    var viewModel: ItemDetailViewModel?
    private let disposeBag = DisposeBag()
    
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView()
    
    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))
        button.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
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

    private func bind() {
        let input = ItemDetailViewModel.Input(
            didTapCheck: checkButton.rx.tap.asObservable()
        )
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.item
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, item in
                owner.navigationItem.title = item.translations.localizedName()
                owner.setUpSection(in: item)
            }).disposed(by: disposeBag)
        
        output?.isAcquired
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
    
    private func setUpSection(in item: Item) {
        let itemDetailInfo = SectionView(contentView: ItemDetailInfoView(item: item))
        sectionsScrollView.addSection(itemDetailInfo)
        if Category.critters.contains(item.category) {
            let seasonView = SectionView(
                title: "Seasonality",
                iconName: "calendar",
                contentView: ItemSeasonView(item: item)
            )
            sectionsScrollView.addSection(seasonView)
        }
    }
}
