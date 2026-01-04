//
//  TurnipPricesCoordinator.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import UIKit

final class TurnipPricesCoordinator: Coordinator {

    enum Route {
        case showResult(
            basePrice: Int,
            pattern: TurnipPricePattern,
            minPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]],
            maxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
        )
        case showValidationAlert(message: String)
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
        case .showResult(let basePrice, let pattern, let minPrices, let maxPrices):
            showResultViewController(basePrice: basePrice, pattern: pattern, minPrices: minPrices, maxPrices: maxPrices)
        case .showValidationAlert(let message):
            showValidationAlert(message: message)
        }
    }

    private func showValidationAlert(message: String) {
        let alert = UIAlertController(
            title: "requiredInputTitle".localized,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .default))

        if let topViewController = rootViewController.topViewController {
            topViewController.present(alert, animated: true)
        } else {
            rootViewController.present(alert, animated: true)
        }
    }

    private func showResultViewController(
        basePrice: Int,
        pattern: TurnipPricePattern,
        minPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]],
        maxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    ) {
        let resultVC = TurnipPriceResultViewController(
            basePrice: basePrice,
            pattern: pattern,
            minPrices: minPrices,
            maxPrices: maxPrices
        )

        // 현재 표시 중인 ViewController에서 present
        if let topViewController = rootViewController.topViewController {
            topViewController.present(resultVC, animated: true)
        } else {
            rootViewController.present(resultVC, animated: true)
        }
    }

    func setUpParent(to coordinator: Coordinator) {
        parentCoordinator = coordinator
    }
}
