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
    
    private var itemDetailInfoView: ItemDetailInfoView?
    private var itemVariantsColorView: ItemVariantsView?
    private var itemVariantsPatternView: ItemVariantsView?
    private var keywordView: ItemKeywordView?
    private var playerView: ItemPlayerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.navigationBar.sizeToFit()
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
        navigationItem.enableMultilineTitle()
    }

    func bind(to viewModel: ItemDetailViewModel) {
        keywordView = ItemKeywordView(item: viewModel.item)
        playerView = ItemPlayerView()
        navigationItem.title = viewModel.item.translations.localizedName()
        setUpSection(in: viewModel.item)
        
        let input = ItemDetailViewModel.Input(
            didTapCheck: checkButton.rx.tap.asObservable(),
            didTapKeyword: keywordView?.didTapKeyword,
            didTapPlay: playerView?.playButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
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
        
        itemVariantsColorView?.didTapImage
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, image in
                owner.itemDetailInfoView?.changeImage(image)
            }).disposed(by: disposeBag)
        
        itemVariantsPatternView?.didTapImage
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, image in
                owner.itemDetailInfoView?.changeImage(image)
            }).disposed(by: disposeBag)
    }
    
    private func setUpSection(in item: Item) {
        setUpDetail(item)
        setUpVariant(item)
        setUpOther(item)
        setUpSaeson(item)
        setUpKeyword(item)
        setUpMaterials(item)
    }
    
    private func setUpDetail(_ item: Item) {
        itemDetailInfoView = ItemDetailInfoView(item: item)
        itemDetailInfoView.flatMap {
            let itemDetailInfo = SectionView(
                title: item.category.rawValue.localized.uppercased(),
                category: item.category,
                contentView: $0
            )
            sectionsScrollView.addSection(itemDetailInfo)
        }
    }
    
    private func setUpVariant(_ item: Item) {
        guard Category.furniture().contains(item.category), item.variations != nil else {
            return
        }
        itemVariantsColorView = ItemVariantsView(item: item.variationsWithColor, mode: .color)
        itemVariantsPatternView = ItemVariantsView(item: item.variationsWithPattern, mode: .pattern)
        
        let isNoColor = item.variations?.compactMap { $0.filename }.filter { $0.suffix(2) == "_0" }.count ?? 1 <= 1
        let isNoPattern = item.patternCustomize == false
        let canBodyCustomize = item.bodyCustomize == true
        let canPatternCustomize = item.patternCustomize == true
        let bodyTitle = "\("Variants".localized) (\(canBodyCustomize ? "Reformable".localized : "Not reformed".localized))"
        let patternTitle = "\("Pattern".localized) (\(canPatternCustomize ? "Reformable".localized : "Not reformed".localized))"
        
        if isNoPattern {
            itemVariantsColorView.flatMap { view in
                let variantsView = SectionView(
                    title: bodyTitle,
                    iconName: "paintbrush.fill",
                    contentView: view
                )
                sectionsScrollView.addSection(variantsView)
            }
        } else if isNoColor {
            itemVariantsPatternView.flatMap { view in
                let variantsView = SectionView(
                    title: patternTitle,
                    iconName: "camera.macro",
                    contentView: view
                )
                sectionsScrollView.addSection(variantsView)
            }
        } else {
            itemVariantsColorView.flatMap { view in
                let variantsView = SectionView(
                    title: bodyTitle,
                    iconName: "paintbrush.fill",
                    contentView: view
                )
                sectionsScrollView.addSection(variantsView)
            }
            itemVariantsPatternView.flatMap { view in
                let variantsView = SectionView(
                    title: patternTitle,
                    iconName: "camera.macro",
                    contentView: view
                )
                sectionsScrollView.addSection(variantsView)
            }
        }
    }
    
    private func setUpOther(_ item: Item) {
        let otherInfoView = SectionView(
            contentView: ItemOtherInfoView(item: item)
        )
        sectionsScrollView.addSection(otherInfoView)
    }
    
    private func setUpSaeson(_ item: Item) {
        guard Category.critters.contains(item.category) else {
            return
        }
        let seasonView = SectionView(
            title: "Seasonality".localized,
            iconName: "calendar",
            contentView: ItemSeasonView(item: item)
        )
        sectionsScrollView.addSection(seasonView)
    }
    
    private func setUpKeyword(_ item: Item) {
        guard item.keyword.isEmpty == false else {
            return
        }
        keywordView.flatMap {
            let keywordListView = SectionView(
                title: "Keyword".localized,
                iconName: "link",
                contentView: $0
            )
            sectionsScrollView.addSection(keywordListView)
        }
    }
    
    private func setUpMaterials(_ item: Item) {
        guard item.recipe?.materials.isEmpty == false else {
            return
        }
        let materialsView = ItemMaterialsView(item: item)
        let materialsSection = SectionView(
            title: "Materials".localized,
            iconName: "book.closed.fill",
            contentView: materialsView
        )
        sectionsScrollView.addSection(materialsSection)
    }
    
    private func setUpPlayer(_ item: Item) {
        guard item.category == .songs else {
            return
        }
        playerView.flatMap {
            let musicSection = SectionView(
                title: "Music Player".localized,
                iconName: "music.note",
                contentView: $0
            )
            sectionsScrollView.addSection(musicSection)
        }
    }
}
