//
//  AnimalsCoordinator.swift
//  ACNH-wiki
//
//  Created by Ari on 11/23/24.
//

import UIKit
import ACNHCore
import ACNHShared

final class AnimalsCoordinator: Coordinator {

    enum Route {
        case animals(for: Category)
        case detailVillager(Villager)
        case detailNPC(NPC)
    }

    var type: CoordinatorType = .animals
    var rootViewController: UINavigationController
    private(set) var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }

    func start() {
        let catalogVC = CatalogViewController(mode: .animals)
        catalogVC.bind(to: CatalogReactor(delegate: self, mode: .animals))
        rootViewController.addChild(catalogVC)
    }

    func transition(for route: Route) {
        switch route {
        case .animals(let category):
            switch category {
            case .villager:
                let viewController = VillagersViewController()
                viewController.bind(to: VillagersReactor(coordinator: self))
                rootViewController.pushViewController(viewController, animated: true)

            case .npc:
                let viewController = NPCViewController()
                viewController.bind(to: NPCReactor(coordinator: self))
                rootViewController.pushViewController(viewController, animated: true)

            default: return
            }
            
        case .detailVillager(let villager):
            let viewController = VillagerDetailViewController()
            viewController.bind(
                to: VillagerDetailReactor(villager: villager, state: .init(villager: villager))
            )
            rootViewController.pushViewController(viewController, animated: true)
            
        case .detailNPC(let npc):
            let viewController = NPCDetailViewController()
            viewController.bind(
                to: NPCDetailReactor(npc: npc, state: .init(npc: npc))
            )
            rootViewController.pushViewController(viewController, animated: true)
        }
    }

    func setUpParent(to coordinator: Coordinator) {
        parentCoordinator = coordinator
    }
}

// MARK: - CatalogReactorDelegate
extension AnimalsCoordinator: CatalogReactorDelegate {
    func showItemList(category: Category) {
        switch category {
        case .villager:
            transition(for: .animals(for: .villager))
        case .npc:
            transition(for: .animals(for: .npc))
        default: return
        }
    }
    
    func showSearchList() {
        // do nothing
    }
}
