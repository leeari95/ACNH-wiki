//
//  TasksEditCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit

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
        tasksEditVC.coordinator = self
        rootViewController.isModalInPresentation = true
        rootViewController.addChild(tasksEditVC)
    }
    
    func present(_ viewController: UIViewController) {
        rootViewController.visibleViewController?.present(viewController, animated: true)
    }
    
    func presentToAddTask() {
        let customTaskVC = CustomTaskViewController()
        delegate = customTaskVC
        customTaskVC.coordinator = self
        customTaskVC.mode = .add
        let navigationVC = UINavigationController(rootViewController: customTaskVC)
        navigationVC.isModalInPresentation = true
        present(navigationVC)
    }
    
    func pushToEditTask(_ task: DailyTask) {
        let customTaskVC = CustomTaskViewController()
        delegate = customTaskVC
        customTaskVC.coordinator = self
        customTaskVC.mode = .edit
        customTaskVC.task = task
        rootViewController.pushViewController(customTaskVC, animated: true)
    }
    
    func presentToIcon() {
        let iconChooserVC = IconChooserViewController()
        iconChooserVC.coordinator = self
        present(UINavigationController(rootViewController: iconChooserVC))
    }
    
    func dismiss(_ viewController: UIViewController) {
        if (viewController as? CustomTaskViewController)?.mode == .add {
            rootViewController.dismiss(animated: true)
        } else {
            rootViewController.popViewController(animated: true)
        }
        delegate = nil
    }
    
    func selectedIcon(_ icon: String) {
        delegate?.seletedIcon(icon)
    }
    
    func finish() {
        parentCoordinator?.childDidFinish(self)
    }
}
