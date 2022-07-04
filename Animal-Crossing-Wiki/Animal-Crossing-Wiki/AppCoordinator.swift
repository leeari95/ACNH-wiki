//
//  AppCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

final class AppCoordinator: Coordinator {
    var type: CoordinatorType = .main
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UITabBarController!
    
    init(rootViewController: UITabBarController = UITabBarController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let dashboardCoordinator = DashboardCoordinator()
        dashboardCoordinator.start()
        addViewController(dashboardCoordinator.rootViewController, title: "Dashboard", icon: "Inv1")
        childCoordinators.append(dashboardCoordinator)
        
        let villagersCoordinator = VillagersCoordinator()
        villagersCoordinator.start()
        addViewController(villagersCoordinator.rootViewController, title: "Villagers", icon: "Inv97")
        childCoordinators.append(villagersCoordinator)
    }
    
    private func addViewController(_ viewController: UIViewController, title: String, icon: String) {
        let iconImage = UIImage(named: icon)?.withRenderingMode(.alwaysOriginal)
        let imageInsets = UIEdgeInsets(top: 15, left: 18, bottom: 15, right: 18)
        
        let tabBarItem = UITabBarItem(title: title, image: iconImage, tag: childCoordinators.count)
        tabBarItem.imageInsets = imageInsets
        viewController.tabBarItem = tabBarItem
        
        rootViewController.addChild(viewController)
    }
}
