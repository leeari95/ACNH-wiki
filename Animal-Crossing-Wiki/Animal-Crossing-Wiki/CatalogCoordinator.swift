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
}
