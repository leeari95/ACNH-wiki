//
//  CollectionCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import UIKit

final class CollectionCoordinator: Coordinator {
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
}
