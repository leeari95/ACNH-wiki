//
//  VillagersCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import UIKit

final class VillagersCoordinator: Coordinator {
    var type: CoordinatorType = .villagers
    var rootViewController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let villagersVC = VillagersViewController()
        villagersVC.viewModel = VillagersViewModel(coordinator: self)
        rootViewController.addChild(villagersVC)
    }
}
