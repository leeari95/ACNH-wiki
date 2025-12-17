//
//  TurnipPricesViewController.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import UIKit
import RxSwift
import SwiftUI

final class TurnipPricesViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
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
    
    private func setUpViews() {
        setUpNavigationItem()
        view.backgroundColor = .acBackground
        view.addSubviews(sectionsScrollView)
        setUpSection()

        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setUpSection() {
        let hosting = UIHostingController(rootView: TurnipPricesPatternSelectionView())
        hosting.view.backgroundColor = .clear
        sectionsScrollView.addSection(
            SectionView(
                title: "저번주 가격 패턴을 골라주세요",
                iconName: "checkmark.circle.dotted",
                contentView: hosting.view
            )
        )
    }
}
