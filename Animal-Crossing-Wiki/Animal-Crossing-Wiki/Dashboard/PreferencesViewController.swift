//
//  PreferencesViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit
import RxSwift

class PreferencesViewController: UIViewController {
    
    var viewModel: PreferencesViewModel?
    
    private let currentHemisphere = BehaviorSubject<Hemisphere?>(value: nil)
    private let currentFruit = BehaviorSubject<Fruit?>(value: nil)
    private let disposeBag = DisposeBag()
    
    private lazy var settingSection = PreferencesSection()
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(title: "Island", iconName: "sun.haze", contentView: settingSection)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        bind()
    }
    
    private func setUp() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "Preferences"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: nil
        )
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func bind() {
        let input = PreferencesViewModel.Input(
            islandNameText: settingSection.islandNameObservable,
            userNameText: settingSection.userNameObservable,
            hemisphereButtonTitle: currentHemisphere.asObservable(),
            startingFruitButtonTitle: currentFruit.asObservable(),
            didTapCancel: navigationItem.leftBarButtonItem?.rx.tap.asObservable(),
            didTapHemisphere: settingSection.hemisphereButtonObservable,
            didTapFruit: settingSection.startingFruitButtonObservable
        )
        
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)

        output?.userInfo
            .compactMap { $0 }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { owner, userInfo in
                owner.settingSection.setUpViews(userInfo)
        }, onError: { error in
            print(error.localizedDescription)
        }).disposed(by: disposeBag)
        
        output?.errorMessage
            .filter { $0 != "" }
            .subscribe(onNext: { errorMessage in
                print(errorMessage)
            }).disposed(by: disposeBag)
        
        output?.didChangeHemisphere
            .compactMap { $0 }
            .compactMap { Hemisphere(rawValue: $0) }
            .subscribe(onNext: { hemisphere in
                self.settingSection.updateHemisphere(hemisphere)
                self.currentHemisphere.onNext(hemisphere)
            }).disposed(by: disposeBag)
        
        output?.didChangeFruit
            .compactMap { $0 }
            .compactMap { Fruit(rawValue: $0) }
            .subscribe(onNext: { fruit in
                self.settingSection.updateFruit(fruit)
                self.currentFruit.onNext(fruit)
            }).disposed(by: disposeBag)
    }
}
