//
//  DashboardCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit

final class DashboardCoordinator: Coordinator {
    
    enum Route {
        case setting
        case about
        case taskEdit
        case villagerDetail(villager: Villager)
        case progress
        case item(category: Category)
        case itemDetail(item: Item)
        case dismiss
    }
    
    let type: CoordinatorType = .dashboard
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UINavigationController!
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let viewController = DashboardViewController()
        viewController.bind(to: DashboardViewModel(coordinator: self))
        viewController.setUpViewModels(
            userInfoVM: UserInfoSectionViewModel(),
            tasksVM: TodaysTasksSesctionViewModel(coordinator: self),
            villagersVM: VillagersSectionViewModel(coordinator: self),
            progressVM: CollectionProgressSectionViewModel(coordinator: self)
        )
        rootViewController.addChild(viewController)
    }
    
    func transition(for route: Route) {
        switch route {
        case .setting:
            let viewController = PreferencesViewController()
            viewController.viewModel = PreferencesViewModel(coordinator: self)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.isModalInPresentation = true
            rootViewController.present(navigationController, animated: true)
        case .about:
            let viewController = AboutViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            rootViewController.present(navigationController, animated: true)
        case .taskEdit:
            let tasksEditCoordinator = TasksEditCoordinator()
            tasksEditCoordinator.parentCoordinator = self
            tasksEditCoordinator.start()
            childCoordinators.append(tasksEditCoordinator)
            rootViewController.present(tasksEditCoordinator.rootViewController, animated: true)
        case .villagerDetail(let villager):
            let viewController = VillagerDetailViewController()
            viewController.viewModel = VillagerDetailViewModel(villager: villager, coordinator: nil)
            let navigationController = UINavigationController(rootViewController: viewController)
            rootViewController.present(navigationController, animated: true)
        case .progress:
            let viewController = CollectionProgressViewController()
            let viewModel = CollectionProgressViewModel(coordinator: self)
            viewController.bind(to: viewModel)
            rootViewController.pushViewController(viewController, animated: true)
        case .item(let category):
            let viewController = ItemsViewController()
            viewController.category = category
            viewController.viewModel = ItemsViewModel(category: category, coordinator: self)
            let navigationController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            navigationController?.pushViewController(viewController, animated: true)
        case .itemDetail(let item):
            let viewController = ItemDetailViewController()
            viewController.viewModel = ItemDetailViewModel(item: item)
            let navigationController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            navigationController?.pushViewController(viewController, animated: true)
        case .dismiss:
            rootViewController.visibleViewController?.dismiss(animated: true)
        }
    }
    
    func dismiss(animated: Bool) {
        rootViewController.visibleViewController?.dismiss(animated: animated)
    }
}
