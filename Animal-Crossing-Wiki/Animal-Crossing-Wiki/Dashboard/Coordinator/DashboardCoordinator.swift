//
//  DashboardCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit

final class DashboardCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UINavigationController!
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let dashboardVC = DashboardViewController()
        dashboardVC.coordinator = self
        rootViewController.addChild(dashboardVC)
    }
    
    func present(_ viewController: UIViewController) {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isModalInPresentation = true
        rootViewController.present(navigationController, animated: true)
    }
}
