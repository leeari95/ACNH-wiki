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
    private var topAnchorConstraint:  NSLayoutConstraint?
    
    init(rootViewController: UITabBarController = UITabBarController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let dashboardCoordinator = DashboardCoordinator()
        dashboardCoordinator.start()
        dashboardCoordinator.setUpParent(to: self)
        addViewController(dashboardCoordinator.rootViewController, title: "Dashboard".localized, icon: "icon-bells-tabbar")
        childCoordinators.append(dashboardCoordinator)
        
        let catalogCoordinator = CatalogCoordinator()
        catalogCoordinator.start()
        catalogCoordinator.setUpParent(to: self)
        addViewController(catalogCoordinator.rootViewController, title: "Catalog".localized, icon: "icon-leaf-tabbar")
        childCoordinators.append(catalogCoordinator)
        
        let villagersCoordinator = VillagersCoordinator()
        villagersCoordinator.start()
        addViewController(villagersCoordinator.rootViewController, title: "Villagers".localized, icon: "icon-book-tabbar")
        childCoordinators.append(villagersCoordinator)
        
        let collectionCoordinator = CollectionCoordinator()
        collectionCoordinator.start()
        collectionCoordinator.setUpParent(to: self)
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

extension AppCoordinator {
    
    func showMusicPlayer() {
        guard playerViewController == nil else {
            playerViewController?.view.isHidden = false
            return
        }
        let viewController = PlayerViewController()
        playerViewController = viewController
        rootViewController.view.addSubviews(viewController.view)
        rootViewController.view.bringSubviewToFront(rootViewController.tabBar)
        viewController.didMove(toParent: rootViewController)
        let viewModel = PlayerViewModel(coordinator: self)
        viewController.bind(to: viewModel)

        let frame = rootViewController.view.frame
        let tabBarHeight = rootViewController.tabBar.frame.height
        viewController.configure(tabBarHeight: tabBarHeight)
        topAnchorConstraint = viewController.view.topAnchor.constraint(
            equalTo: rootViewController.view.topAnchor,
            constant: frame.height - rootViewController.tabBar.frame.height - 60
        )
        
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
        let tabBarHeight = rootViewController.tabBar.frame.height
        UIView.animate(withDuration: 0.4) {
            self.topAnchorConstraint?.constant = frame.height - tabBarHeight - 60
            self.rootViewController.view.layoutIfNeeded()
        }
    }
    
    func maximize() {
        let frame = rootViewController.view.frame
        UIView.animate(withDuration: 0.4) {
            self.topAnchorConstraint?.constant = frame.height - 600
            self.rootViewController.view.layoutIfNeeded()
        }
    }
    
    func removePlayerViewController() {
        playerViewController?.view.isHidden = true
        MusicPlayerManager.shared.close()
    }
}
