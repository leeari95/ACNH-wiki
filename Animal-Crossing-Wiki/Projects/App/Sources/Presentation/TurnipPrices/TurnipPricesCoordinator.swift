//
//  TurnipPricesCoordinator.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import UIKit

final class TurnipPricesCoordinator: Coordinator {

    enum Route {
    }

    var type: CoordinatorType = .turnipPrices
    var rootViewController: UINavigationController
    private(set) var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }

    func start() {
        let turnipPricesVC = TurnipPricesViewController()
        turnipPricesVC.bind(to: TurnipPricesReactor(coordinator: self, state: .init()))
        rootViewController.addChild(turnipPricesVC)
    }

    func transition(for route: Route) {
        switch route {
            
        }
    }

    func setUpParent(to coordinator: Coordinator) {
        parentCoordinator = coordinator
    }
}
