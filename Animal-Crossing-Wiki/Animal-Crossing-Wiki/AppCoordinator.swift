//
//  AppCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UITabBarController!
    
    init(rootViewController: UITabBarController = UITabBarController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let iconImage = UIImage(named: "Inv1")?.withRenderingMode(.alwaysOriginal)
        
        let dashboardItem = UITabBarItem(title: "Dashboard", image: iconImage, tag: 0)
        dashboardItem.imageInsets = UIEdgeInsets(top: 15, left: 18, bottom: 15, right: 18)
        
        let dashboardVC = UIStoryboard.instantiateDashboardViewController()
        dashboardVC.tabBarItem = dashboardItem
        
        rootViewController.viewControllers = [dashboardVC]
    }
}

extension UIStoryboard {
    private static var main: UIStoryboard {
        return UIStoryboard(name: "Dashboard", bundle: nil)
    }
    
    static func instantiateDashboardViewController() -> UINavigationController {
        let viewController = main.instantiateViewController(
            withIdentifier: "DashboardViewController"
        ) as? UINavigationController ?? UINavigationController()
        return viewController
    }
}
