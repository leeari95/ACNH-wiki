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
    private var topAnchorConstraint: NSLayoutConstraint?

    init(rootViewController: UITabBarController = UITabBarController()) {
        self.rootViewController = rootViewController
    }

    func start() {
        // iPad에서도 하단 탭바 사용
        if #available(iOS 18.0, *) {
            rootViewController.mode = .tabBar
            rootViewController.traitOverrides.horizontalSizeClass = .compact
        }

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

        let animalsCoordinator = AnimalsCoordinator()
        animalsCoordinator.start()
        addViewController(animalsCoordinator.rootViewController, title: "animals".localized, icon: "icon-book-tabbar")
        childCoordinators.append(animalsCoordinator)

        let collectionCoordinator = CollectionCoordinator()
        collectionCoordinator.start()
        collectionCoordinator.setUpParent(to: self)
        addViewController(collectionCoordinator.rootViewController, title: "Collection".localized, icon: "icon-cardboard-tabbar")
        childCoordinators.append(collectionCoordinator)

        // 탭바 설정 후 튜토리얼 표시 (view hierarchy가 완전히 설정된 후)
        showTutorialIfNeeded()
    }

    private func addViewController(_ viewController: UIViewController, title: String, icon: String) {
        let iconImage = UIImage(named: icon)?.withRenderingMode(.alwaysOriginal)

        let tabBarItem = UITabBarItem(title: title, image: iconImage, tag: childCoordinators.count)
        viewController.tabBarItem = tabBarItem

        rootViewController.addChild(viewController)
    }

    private func showTutorialIfNeeded() {
        guard TutorialReactor.shouldShowTutorial() else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let totalPages = TutorialViewController.pageContents.count
            let reactor = TutorialReactor(totalPages: totalPages)
            let tutorialVC = TutorialViewController(reactor: reactor)
            tutorialVC.modalPresentationStyle = .fullScreen
            self.rootViewController.present(tutorialVC, animated: true)
        }
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
        let viewModel = PlayerReactor(coordinator: self)
        viewController.bind(to: viewModel)

        let frame = rootViewController.view.frame
        viewController.configure()
        topAnchorConstraint = viewController.view.topAnchor.constraint(
            equalTo: rootViewController.view.topAnchor,
            constant: frame.height - rootViewController.tabBar.frame.height - PlayerSheetMetrics.minimizedHeight
        )

        topAnchorConstraint.flatMap {
            NSLayoutConstraint.activate([
                viewController.view.bottomAnchor.constraint(equalTo: rootViewController.tabBar.topAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
                $0
            ])
        }
    }

    func minimize() {
        let frame = rootViewController.view.frame
        let tabBarHeight = rootViewController.tabBar.frame.height
        topAnchorConstraint?.constant = frame.height - tabBarHeight - PlayerSheetMetrics.minimizedHeight
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            self.rootViewController.view.layoutIfNeeded()
        }
    }

    func maximize() {
        let frame = rootViewController.view.frame
        let tabBarHeight = rootViewController.tabBar.frame.height
        rootViewController.view.bringSubviewToFront(rootViewController.tabBar)
        topAnchorConstraint?.constant = frame.height - tabBarHeight - PlayerSheetMetrics.maximizedHeight
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            self.rootViewController.view.layoutIfNeeded()
        }
    }

    func removePlayerViewController() {
        playerViewController?.view.removeFromSuperview()
        playerViewController = nil
        MusicPlayerManager.shared.close()
    }
    
    private enum PlayerSheetMetrics {
        static let minimizedHeight: CGFloat = 80
        static let maximizedHeight: CGFloat = 450
    }
}
