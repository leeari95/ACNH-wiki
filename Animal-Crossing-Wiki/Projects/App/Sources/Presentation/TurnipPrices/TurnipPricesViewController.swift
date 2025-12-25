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

    private lazy var hostingController: UIHostingController<TurnipPricesSectionsView> = {
        let controller = UIHostingController(rootView: TurnipPricesSectionsView())
        controller.view.backgroundColor = .clear
        return controller
    }()

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

        addChild(hostingController)
        view.addSubviews(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
}
