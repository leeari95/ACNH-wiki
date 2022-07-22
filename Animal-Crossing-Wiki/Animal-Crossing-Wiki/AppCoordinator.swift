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
    
    private var playerViewController: PlayerViewController?
    private lazy var topAnchorConstraint = self.playerViewController?.view.topAnchor.constraint(
        equalTo: rootViewController.view.topAnchor,
        constant: rootViewController.view.frame.height
    )
    
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
    
    private func setUpMusicPlayer(_ viewController: PlayerViewController) {
        playerViewController = viewController
        rootViewController.view.addSubviews(viewController.view)
        rootViewController.view.bringSubviewToFront(rootViewController.tabBar)
        viewController.didMove(toParent: rootViewController)
        let viewModel = PlayerViewModel(coordinator: self)
        viewController.bind(to: viewModel)

        let frame = rootViewController.view.frame
        let tabBarHeight = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 34) + rootViewController.tabBar.frame.height
        viewController.configure(tabBarHeight: tabBarHeight)
        self.topAnchorConstraint?.constant = frame.height - tabBarHeight - 60
        
        topAnchorConstraint.flatMap {
            NSLayoutConstraint.activate([
                viewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
                $0
            ])
        }
        
    }
    
    func minimize() {
        let frame = rootViewController.view.frame
        let tabBarHeight = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 34) + rootViewController.tabBar.frame.height
        UIView.animate(withDuration: 0.4) {
            self.topAnchorConstraint?.constant = frame.height - tabBarHeight - 30
            self.rootViewController.view.layoutIfNeeded()
        }
    }
    
    func maximize() {
        UIView.animate(withDuration: 0.4) {
            self.topAnchorConstraint?.constant = 300
            self.rootViewController.view.layoutIfNeeded()
        }
    }
    
    func removePlayerViewController() {
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
        
    }
}
