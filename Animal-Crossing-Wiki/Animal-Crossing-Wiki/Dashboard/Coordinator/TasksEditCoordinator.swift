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
    func updateAmount(title: String)
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
    
    func presentToAddTask() {
        let customTaskVC = CustomTaskViewController()
        delegate = customTaskVC
        customTaskVC.viewModel = CustomTaskViewModel(coordinator: self, task: nil)
        customTaskVC.mode = .add
        let navigationVC = UINavigationController(rootViewController: customTaskVC)
        navigationVC.isModalInPresentation = true
        present(navigationVC)
    }
    
    func pushToEditTask(_ task: DailyTask) {
        let customTaskVC = CustomTaskViewController()
        delegate = customTaskVC
        customTaskVC.viewModel = CustomTaskViewModel(coordinator: self, task: task)
        customTaskVC.mode = .edit
        rootViewController.pushViewController(customTaskVC, animated: true)
    }
    
    func presentToIcon() {
        let iconChooserVC = IconChooserViewController()
        iconChooserVC.coordinator = self
        present(UINavigationController(rootViewController: iconChooserVC))
    }

    func presentToAmount(currentAmount: String, disposeBag: DisposeBag) {
        rootViewController.visibleViewController?.showSeletedItemAlert(
            Array(1...20).map { $0.description },
            currentItem: currentAmount
        ).subscribe(onNext: { title in
            self.delegate?.updateAmount(title: title)
        }).disposed(by: disposeBag)
    }
    
    func dismiss(_ viewController: UIViewController) {
        if (viewController as? CustomTaskViewController)?.mode == .add {
            dismiss(animated: true)
        } else {
            rootViewController.popViewController(animated: true)
        }
        delegate = nil
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
