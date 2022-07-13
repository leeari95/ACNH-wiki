//
//  VillagerDetailViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit
import RxSwift

class VillagerDetailViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton()
        button.tintColor = .red
        return button
    }()
    
    private lazy var houseButton: UIButton = {
        let button = UIButton()
        button.tintColor = .acNavigationBarTint
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark.circle.fill"),
                style: .plain,
                target: self,
                action: nil
            )
            navigationItem.leftBarButtonItem?.rx.tap
                .withUnretained(self)
                .subscribe(onNext: { owner, _ in
                    owner.dismiss(animated: true)
                }).disposed(by: disposeBag)
        }
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
        let likeBarButton = UIBarButtonItem(customView: likeButton)
        let houseBarButton = UIBarButtonItem(customView: houseButton)
        navigationItem.rightBarButtonItems = [houseBarButton, likeBarButton]
    }
    
    func bind(to viewModel: VillagerDetailViewModel) {
        let input = VillagerDetailViewModel.Input(
            didTapHeart: likeButton.rx.tap.asObservable(),
            didTapHouse: houseButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        let config = UIImage.SymbolConfiguration(scale: .large)
        
        output.villager
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, villager in
                let detailSection = VillagerDetailView(villager)
                owner.sectionsScrollView.addSection(SectionView(contentView: detailSection))
                owner.navigationItem.title = villager.translations.localizedName()
            }).disposed(by: disposeBag)
        
        output.villager
            .compactMap { $0.houseImage }
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe(onNext: { owner, houseImage in
                owner.addHouseSection(houseImage)
            }).disposed(by: disposeBag)
        
        output.isLiked
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isLiked in
                owner.likeButton.setImage(
                    UIImage(systemName: isLiked ? "heart.fill" : "heart", withConfiguration: config),
                    for: .normal
                )
            }).disposed(by: disposeBag)
        
        output.isResident
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isResident in
                    owner.houseButton.setImage(
                        UIImage(systemName: isResident ? "house.fill" : "house", withConfiguration: config),
                        for: .normal
                    )
            }).disposed(by: disposeBag)
    }
    
    private func addHouseSection(_ houseImage: String) {
        let houseSection = VillagerHouseView(houseImage)
        let sectionView = SectionView(
            title: "Villager house".localized,
            iconName: "house.circle.fill",
            contentView: houseSection
        )
        self.sectionsScrollView.addSection(sectionView)
    }
}
