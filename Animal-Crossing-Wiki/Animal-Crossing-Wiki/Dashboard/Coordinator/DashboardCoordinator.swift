//
//  DashboardCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit

final class DashboardCoordinator: Coordinator {
    let type: CoordinatorType = .dashboard
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
        rootViewController.present(viewController, animated: true)
    }
    
    func presentToSetting() {
        let preferencesVC = PreferencesViewController()
        preferencesVC.viewModel = PreferencesViewModel()
        let navigationController = UINavigationController(rootViewController: preferencesVC)
        navigationController.isModalInPresentation = true
        present(navigationController)
    }
    
    func presentToAbout() {
        let aboutVC = AboutViewController()
        let navigationController = UINavigationController(rootViewController: aboutVC)
        present(navigationController)
    }
    
    func presentToTaskEdit() {
        let tasksEditCoordinator = TasksEditCoordinator()
        tasksEditCoordinator.parentCoordinator = self
        tasksEditCoordinator.start()
        childCoordinators.append(tasksEditCoordinator)
        present(tasksEditCoordinator.rootViewController)
    }
}
