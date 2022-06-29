//
//  TasksEditCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit
import RxSwift

protocol CustomTaskViewControllerDelegate: AnyObject {
    func seletedIcon(_ icon: String)
}

final class TasksEditCoordinator: Coordinator {
    let type: CoordinatorType = .taskEdit
    weak var parentCoordinator: DashboardCoordinator?
    var childCoordinators: [Coordinator] = []
    weak var delegate: CustomTaskViewControllerDelegate?
    private(set) var rootViewController: UINavigationController!
    
    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }
    
    func start() {
        let tasksEditVC = TaskEditViewController()
        tasksEditVC.viewModel = TasksEditViewModel(coordinator: self)
        rootViewController.isModalInPresentation = true
        rootViewController.addChild(tasksEditVC)
    }
    
    func present(_ viewController: UIViewController) {
        rootViewController.visibleViewController?.present(viewController, animated: true)
    }
    
    func pushToCustomTaskVC(_ task: DailyTask) {
        let customTaskVC = CustomTaskViewController()
        delegate = customTaskVC
        if task.icon == "plus" {
            customTaskVC.viewModel = CustomTaskViewModel(coordinator: self, task: nil)
            customTaskVC.mode = .add
        } else {
            customTaskVC.viewModel = CustomTaskViewModel(coordinator: self, task: task)
            customTaskVC.mode = .edit
        }
        rootViewController.pushViewController(customTaskVC, animated: true)
    }
    
    func presentToIcon() {
        let iconChooserVC = IconChooserViewController()
        iconChooserVC.coordinator = self
        present(UINavigationController(rootViewController: iconChooserVC))
    }
    
    func popVC(animated: Bool) {
        rootViewController.popViewController(animated: animated)
    }
    
    func dismiss(animated: Bool) {
        rootViewController.visibleViewController?.dismiss(animated: animated)
    }
    
    func selectedIcon(_ icon: String) {
        delegate?.seletedIcon(icon)
    }
    
    func finish() {
        rootViewController.dismiss(animated: true) {
            self.parentCoordinator?.childDidFinish(self)
        }
    }
}
