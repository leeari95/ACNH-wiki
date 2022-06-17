//
//  PreferencesViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit
import RxSwift

class PreferencesViewController: UIViewController {
    
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
    }
    
    @objc private func didTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func didTapHemisphere(_ sender: UIButton) {
        showSeletedItemAlert(
            Hemisphere.allCases.map { $0.rawValue },
            currentItem: sender.titleLabel?.text ?? ""
        ).subscribe(onNext: { title in
            self.settingSection.updateHemisphere(Hemisphere(rawValue: title) ?? .north)
        }).disposed(by: disposeBag)
    }
    
    @objc private func didTapFruit(_ sender: UIButton) {
        showSeletedItemAlert(
            Fruit.allCases.map { $0.imageName },
            currentItem: settingSection.currentFruit
        ).subscribe(onNext: { title in
            self.settingSection.updateFruit(Fruit(rawValue: title.lowercased()) ?? .apple)
        }).disposed(by: disposeBag)
    }
    
}
