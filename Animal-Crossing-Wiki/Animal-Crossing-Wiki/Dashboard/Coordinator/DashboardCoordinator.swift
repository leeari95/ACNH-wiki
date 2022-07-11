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
        case customTask(task: DailyTask)
        case iconChooser
        case villagerDetail(villager: Villager)
        case progress
        case item(category: Category)
        case itemDetail(item: Item)
        case pop
        case dismiss
    }
    
    let type: CoordinatorType = .dashboard
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UINavigationController!
    
    weak var delegate: CustomTaskViewControllerDelegate?
    
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
            let viewController = TaskEditViewController()
            viewController.viewModel = TasksEditViewModel(coordinator: self)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.isModalInPresentation = true
            rootViewController.present(navigationController, animated: true)
        case .customTask(let task):
            let viewController = CustomTaskViewController()
            delegate = viewController
            if task.icon == "plus" {
                viewController.viewModel = CustomTaskViewModel(coordinator: self, task: nil)
                viewController.mode = .add
            } else {
                viewController.viewModel = CustomTaskViewModel(coordinator: self, task: task)
                viewController.mode = .edit
            }
            let navigationController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            navigationController?.pushViewController(viewController, animated: true)
        case .iconChooser:
            let viewController = IconChooserViewController()
            viewController.coordinator = self
            let navigationController = UINavigationController(rootViewController: viewController)
            rootViewController.visibleViewController?.present(navigationController, animated: true)
        case .villagerDetail(let villager):
            let viewController = VillagerDetailViewController()
            viewController.bind(to: VillagerDetailViewModel(villager: villager))
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
            rootViewController.pushViewController(viewController, animated: true)
        case .itemDetail(let item):
            let viewController = ItemDetailViewController()
            viewController.viewModel = ItemDetailViewModel(item: item)
            rootViewController.pushViewController(viewController, animated: true)
        case .pop:
            rootViewController.visibleViewController?.navigationController?.popViewController(animated: true)
        case .dismiss:
            rootViewController.visibleViewController?.navigationController?.dismiss(animated: true)
        }
    }
    
    func selectedIcon(_ icon: String) {
        delegate?.selectedIcon(icon)
    }
}

protocol CustomTaskViewControllerDelegate: AnyObject {
    func selectedIcon(_ icon: String)
}
