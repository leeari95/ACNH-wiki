//
//  CatalogCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit

final class CatalogCoordinator: Coordinator {
    var type: CoordinatorType = .catalog
    var rootViewController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let catalogVC = CatalogViewController()
        catalogVC.viewModel = CatalogViewModel(coordinator: self)
        rootViewController.addChild(catalogVC)
    }
    
    func pushToItems(category: Category) {
        let itemsVC = ItemsViewController()
        itemsVC.category = category
        itemsVC.viewModel = ItemsViewModel(category: category, coordinator: self)
        rootViewController.pushViewController(itemsVC, animated: true)
    }
    
    func pushToItemsDetail(_ item: Item) {
        let itemDetailVC = ItemDetailViewController()
        itemDetailVC.viewModel = ItemDetailViewModel(item: item)
        rootViewController.pushViewController(itemDetailVC, animated: true)
    }
}
