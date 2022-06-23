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
    }
    
    private func setUp() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "Preferences"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapCancelButton(_:))
        )
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        settingSection.addTargets(self, hemisphere: #selector(didTapHemisphere(_:)), fruit: #selector(didTapFruit(_:)))
        
        bind()
    }
    
    private func bind() {
        let input = PreferencesViewModel.Input(
            islandNameText: settingSection.islandNameObservable,
            userNameText: settingSection.userNameObservable,
            hemisphereButtonTitle: currentHemisphere.asObservable(),
            startingFruitButtonTitle: currentFruit.asObservable()
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
    }
    
    @objc private func didTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func didTapHemisphere(_ sender: UIButton) {
        showSeletedItemAlert(
            Hemisphere.allCases.map { $0.rawValue },
            currentItem: sender.titleLabel?.text
        ).subscribe(onNext: { title in
            Hemisphere(rawValue: title)
                .flatMap {
                    self.settingSection.updateHemisphere($0)
                    self.currentHemisphere.onNext($0)
                }
        }).disposed(by: disposeBag)
    }
    
    @objc private func didTapFruit(_ sender: UIButton) {
        showSeletedItemAlert(
            Fruit.allCases.map { $0.imageName },
            currentItem: settingSection.currentFruit.imageName
        ).subscribe(onNext: { title in
            Fruit(rawValue: title.lowercased())
                .flatMap {
                    self.settingSection.updateFruit($0)
                    self.currentFruit.onNext($0)
                }
        }).disposed(by: disposeBag)
    }
}
