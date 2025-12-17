//
//  TurnipPricesViewController.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import UIKit
import RxSwift

final class TurnipPricesViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    private func setUpViews() {
        setUpNavigationItem()
        view.backgroundColor = .acBackground
        view.addSubviews(sectionsScrollView)

        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    private func setUpNavigationItem() {
        navigationItem.title = "turnipPrices".localized
    }

    func bind(to reactor: TurnipPricesReactor) {
        self.rx.viewDidLoad
            .map { TurnipPricesReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)
    }

    private func addHouseSection(_ houseImage: String) {
        let houseSection = VillagerHouseView(houseImage)
        let sectionView = SectionView(
            title: "Villager house".localized,
            iconName: "house.circle.fill",
            contentView: houseSection
        )
        sectionsScrollView.addSection(sectionView)
    }
}
