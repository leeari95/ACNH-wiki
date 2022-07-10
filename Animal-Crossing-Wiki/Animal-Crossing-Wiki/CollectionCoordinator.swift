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
        case progress
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
            let itemsVC = ItemsViewController()
            itemsVC.category = category
            itemsVC.viewModel = ItemsViewModel(category: category, coordinator: self, mode: mode)
            let viewController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            viewController?.pushViewController(itemsVC, animated: true)
        case .itemDetail(let item):
            let itemDetailVC = ItemDetailViewController()
            itemDetailVC.viewModel = ItemDetailViewModel(item: item)
            let viewController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            viewController?.pushViewController(itemDetailVC, animated: true)
        case .progress:
            let viewController = CollectionProgressViewController()
            let viewModel = CollectionProgressViewModel(coordinator: self)
            viewController.bind(to: viewModel)
            rootViewController.present(UINavigationController(rootViewController: viewController), animated: true)
        case .dismiss:
            rootViewController.visibleViewController?.dismiss(animated: true)
        }
    }
}
