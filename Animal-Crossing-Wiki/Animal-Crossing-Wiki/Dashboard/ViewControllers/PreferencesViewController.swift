//
//  PreferencesViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit
import RxSwift

class PreferencesViewController: UIViewController {
    
    private let currentHemisphere = BehaviorSubject<Hemisphere?>(value: nil)
    private let currentFruit = BehaviorSubject<Fruit?>(value: nil)
    private let disposeBag = DisposeBag()
    
    private lazy var settingSection = PreferencesView()
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(title: "Island".localized, iconName: "leaf.fill", contentView: settingSection)
    )
    
    private lazy var cancelButton: UIBarButtonItem = {
        return .init(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: nil
        )
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "Preferences".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func bind(to viewModel: PreferencesViewModel) {
        let input = PreferencesViewModel.Input(
            islandNameText: settingSection.islandNameObservable,
            userNameText: settingSection.userNameObservable,
            hemisphereButtonTitle: currentHemisphere.asObservable(),
            startingFruitButtonTitle: currentFruit.asObservable(),
            didTapCancel: cancelButton.rx.tap.asObservable(),
            didTapHemisphere: settingSection.hemisphereButtonObservable,
            didTapFruit: settingSection.startingFruitButtonObservable
        )
        
        let output = viewModel.transform(input: input, disposeBag: disposeBag)

        output.userInfo
            .compactMap { $0 }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { owner, userInfo in
                owner.settingSection.setUpViews(userInfo)
        }, onError: { error in
            print(error.localizedDescription)
        }).disposed(by: disposeBag)
        
        output.errorMessage
            .filter { $0 != "" }
            .subscribe(onNext: { errorMessage in
                print(errorMessage)
            }).disposed(by: disposeBag)
        
        output.didChangeHemisphere
            .compactMap { $0 }
            .compactMap { Hemisphere(rawValue: $0) }
            .withUnretained(self)
            .subscribe(onNext: { owner, hemisphere in
                owner.settingSection.updateHemisphere(hemisphere)
                owner.currentHemisphere.onNext(hemisphere)
            }).disposed(by: disposeBag)
        
        output.didChangeFruit
            .compactMap { $0 }
            .compactMap { Fruit(rawValue: $0) }
            .withUnretained(self)
            .subscribe(onNext: { owner, fruit in
                owner.settingSection.updateFruit(fruit)
                owner.currentFruit.onNext(fruit)
            }).disposed(by: disposeBag)
        
        setUpAppSettings(to: AppSettingViewModel())
    }
    
    private func setUpAppSettings(to viewModel: AppSettingViewModel) {
        sectionsScrollView.addSection(
            SectionView(title: "App Settings".localized, iconName: "square.and.pencil", contentView: AppSettingView(viewModel: viewModel))
        )
    }
}
