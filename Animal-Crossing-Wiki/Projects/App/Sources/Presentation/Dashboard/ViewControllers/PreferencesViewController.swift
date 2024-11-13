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
    private let currentReputation = BehaviorRelay<String?>(value: nil)
    let disposeBag = DisposeBag()

    private lazy var settingSection = PreferencesView()
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(title: "island".localized.localizedCapitalized, iconName: "leaf.fill", contentView: settingSection)
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
        navigationItem.title = "Preferences".localized
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
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.showSelectedItemAlert(
                    Hemisphere.allCases.map { $0.rawValue.localized },
                    currentItem: owner.currentHemisphere.value
                ).map { PreferencesReactor.Action.hemishphere(title: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: owner.disposeBag)
            }).disposed(by: disposeBag)

        settingSection.reputationButtonObservable
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.showSelectedItemAlert(
                    ["⭐️", "⭐️⭐️", "⭐️⭐️⭐️", "⭐️⭐️⭐️⭐️", "⭐️⭐️⭐️⭐️⭐️"],
                    currentItem: owner.currentReputation.value
                ).map { PreferencesReactor.Action.reputation($0) }
                    .bind(to: reactor.action)
                    .disposed(by: owner.disposeBag)
            }).disposed(by: disposeBag)

        settingSection.startingFruitButtonObservable
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.showSelectedItemAlert(
                    Fruit.allCases.map { $0.rawValue.lowercased().localized },
                    currentItem: owner.currentFruit.value
                ).map { PreferencesReactor.Action.fruit(title: $0)}
                    .bind(to: reactor.action)
                    .disposed(by: owner.disposeBag)
            }).disposed(by: disposeBag)

        reactor.state
            .compactMap { $0.userInfo }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, userInfo in
                owner.settingSection.setUpViews(userInfo)
                owner.currentHemisphere.accept(userInfo.hemisphere.rawValue.localized)
                owner.currentFruit.accept(userInfo.islandFruit.rawValue.localized)
                owner.currentReputation.accept(String(repeating: "⭐️", count: userInfo.islandReputation + 1))
            }).disposed(by: disposeBag)

        setUpAppSettings(to: appSettingReactor)
    }

    private func setUpAppSettings(to reactor: AppSettingReactor) {
        sectionsScrollView.addSection(
            SectionView(title: "App Settings".localized, iconName: "square.and.pencil", contentView: AppSettingView(reactor: reactor))
        )
    }
}
