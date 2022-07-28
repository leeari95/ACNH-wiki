//
//  PreferencesViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit
import RxSwift
import RxRelay

class PreferencesViewController: UIViewController {
    
    private let currentHemisphere = BehaviorRelay<String?>(value: nil)
    private let currentFruit = BehaviorRelay<String?>(value: nil)
    let disposeBag = DisposeBag()
    
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
    
    func bind(to reactor: PreferencesReactor, appSettingReactor: AppSettingReactor) {
        cancelButton.rx.tap
            .map { PreferencesReactor.Action.cancel }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        settingSection.islandNameObservable
            .map { PreferencesReactor.Action.islandName($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        settingSection.userNameObservable
            .map { PreferencesReactor.Action.userName($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        settingSection.hemisphereButtonObservable
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.showSelectedItemAlert(
                    Hemisphere.allCases.map { $0.rawValue.localized },
                    currentItem: self.currentHemisphere.value
                ).map { PreferencesReactor.Action.hemishphere(title: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
        
        settingSection.startingFruitButtonObservable
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.showSelectedItemAlert(
                    Fruit.allCases.map { $0.rawValue.localized },
                    currentItem: self.currentFruit.value
                ).map { PreferencesReactor.Action.fruit(title: $0)}
                    .bind(to: reactor.action)
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
        
        reactor.state
            .compactMap { $0.userInfo }
            .withUnretained(self)
            .subscribe(onNext: { owner, userInfo in
                owner.settingSection.setUpViews(userInfo)
                owner.currentHemisphere.accept(userInfo.hemisphere.rawValue.localized)
                owner.currentFruit.accept(userInfo.islandFruit.rawValue.localized)
            }).disposed(by: disposeBag)
        
        setUpAppSettings(to: appSettingReactor)
    }
    
    private func setUpAppSettings(to reactor: AppSettingReactor) {
        sectionsScrollView.addSection(
            SectionView(title: "App Settings".localized, iconName: "square.and.pencil", contentView: AppSettingView(reactor: reactor))
        )
    }
}
