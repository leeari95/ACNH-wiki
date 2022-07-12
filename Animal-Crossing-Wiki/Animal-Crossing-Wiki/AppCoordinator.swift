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
        addViewController(dashboardCoordinator.rootViewController, title: "Dashboard".localized, icon: "icon-bells-tabbar")
        childCoordinators.append(dashboardCoordinator)
        
        let catalogCoordinator = CatalogCoordinator()
        catalogCoordinator.start()
        addViewController(catalogCoordinator.rootViewController, title: "Catalog".localized, icon: "icon-leaf-tabbar")
        childCoordinators.append(catalogCoordinator)
        
        let villagersCoordinator = VillagersCoordinator()
        villagersCoordinator.start()
        addViewController(villagersCoordinator.rootViewController, title: "Villagers".localized, icon: "icon-book-tabbar")
        childCoordinators.append(villagersCoordinator)
        
        let collectionCoordinator = CollectionCoordinator()
        collectionCoordinator.start()
        addViewController(collectionCoordinator.rootViewController, title: "Collection".localized, icon: "icon-cardboard-tabbar")
        childCoordinators.append(collectionCoordinator)
    }
    
    private func addViewController(_ viewController: UIViewController, title: String, icon: String) {
        let iconImage = UIImage(named: icon)?.withRenderingMode(.alwaysOriginal)
        
        let tabBarItem = UITabBarItem(title: title, image: iconImage, tag: childCoordinators.count)
        viewController.tabBarItem = tabBarItem
        
        rootViewController.addChild(viewController)
    }
}
