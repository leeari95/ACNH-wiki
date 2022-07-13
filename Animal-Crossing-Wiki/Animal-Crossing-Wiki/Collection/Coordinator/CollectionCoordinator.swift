//
//  CollectionCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import UIKit

final class CollectionCoordinator: Coordinator {
    enum Route {
        case items(category: Category, mode: ItemsViewModel.Mode)
        case itemDetail(item: Item)
        case dismiss
    }
    
    var type: CoordinatorType = .collection
    var childCoordinators: [Coordinator] = []
    let rootViewController: UINavigationController
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let collectionVC = CollectionViewController()
        collectionVC.bind(to: CollectionViewModel(coordinator: self))
        rootViewController.addChild(collectionVC)
    }

    func transition(for route: Route) {
        switch route {
        case .items(let category, let mode):
            let viewController = ItemsViewController()
            viewController.bind(to: ItemsViewModel(category: category, coordinator: self, mode: mode))
            let navigationController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            navigationController?.pushViewController(viewController, animated: true)
        case .itemDetail(let item):
            let viewController = ItemDetailViewController()
            viewController.bind(to: ItemDetailViewModel(item: item))
            let navigationController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            navigationController?.pushViewController(viewController, animated: true)
        case .dismiss:
            rootViewController.visibleViewController?.dismiss(animated: true)
        }
    }
}
