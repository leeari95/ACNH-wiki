//
//  VillagersCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import UIKit

final class VillagersCoordinator: Coordinator {
    
    enum Route {
        case detail(villager: Villager)
    }
    
    var type: CoordinatorType = .villagers
    var rootViewController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let villagersVC = VillagersViewController()
        villagersVC.bind(to: VillagersReactor(coordinator: self))
        rootViewController.addChild(villagersVC)
    }
    
    func transition(for route: Route) {
        switch route {
        case .detail(let villager):
            let viewController = VillagerDetailViewController()
            viewController.bind(
                to: VillagerDetailReactor(villager: villager, state: .init(villager: villager))
            )
            rootViewController.pushViewController(viewController, animated: true)
        }
    }
}
