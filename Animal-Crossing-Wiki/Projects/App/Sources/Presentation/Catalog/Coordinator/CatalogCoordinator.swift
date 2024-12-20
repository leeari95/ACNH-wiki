//
//  CatalogCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit

final class CatalogCoordinator: Coordinator {

    enum Route {
        case items(for: Category)
        case itemDetail(_ item: Item)
        case keyword(title: String, keyword: Keyword)
        case search
    }

    var type: CoordinatorType = .catalog
    var rootViewController: UINavigationController
    private(set) var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }

    func start() {
        let catalogVC = CatalogViewController(mode: .item)
        catalogVC.bind(to: CatalogReactor(delegate: self))
        rootViewController.addChild(catalogVC)
    }

    func transition(for route: Route) {
        switch route {
        case .items(let category):
            let viewController = ItemsViewController()
            viewController.bind(to: ItemsReactor(category: category, coordinator: self))
            rootViewController.pushViewController(viewController, animated: true)

        case .itemDetail(let item):
            let viewController = ItemDetailViewController()
            viewController.bind(to: ItemDetailReactor(item: item, coordinator: self))
            rootViewController.pushViewController(viewController, animated: true)
        case .keyword(let title, let keyword):
            let viewController = ItemsViewController()
            viewController.bind(to: ItemsReactor(coordinator: self, mode: .keyword(title: title, category: keyword)))
            rootViewController.pushViewController(viewController, animated: true)
            
        case .search:
            let viewController = ItemsViewController()
            viewController.bind(to: ItemsReactor(coordinator: self, mode: .search))
            rootViewController.pushViewController(viewController, animated: true)
        }
    }

    func setUpParent(to coordinator: Coordinator) {
        parentCoordinator = coordinator
    }
}

extension CatalogCoordinator: CatalogReactorDelegate {
    func showItemList(category: Category) {
        transition(for: .items(for: category))
    }
    
    func showSearchList() {
        transition(for: .search)
    }
}
