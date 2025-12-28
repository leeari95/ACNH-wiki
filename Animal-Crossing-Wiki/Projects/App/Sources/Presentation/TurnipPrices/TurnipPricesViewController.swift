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
    private var reactor: TurnipPricesReactor?

    private lazy var hostingController: UIHostingController<TurnipPricesSectionsView>? = {
        guard let reactor = reactor else { return nil }
        let controller = UIHostingController(rootView: TurnipPricesSectionsView(reactor: reactor))
        controller.view.backgroundColor = .clear
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        view.backgroundColor = .acBackground
    }

    private func setUpNavigationItem() {
        navigationItem.title = "turnipPrices".localized
    }

    func bind(to reactor: TurnipPricesReactor) {
        self.reactor = reactor

        self.rx.viewDidLoad
            .map { TurnipPricesReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        setUpHostingController()
    }

    private func setUpHostingController() {
        guard let hostingController = hostingController else { return }

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
