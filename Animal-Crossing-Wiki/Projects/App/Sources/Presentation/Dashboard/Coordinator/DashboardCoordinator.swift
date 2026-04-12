//
//  DashboardCoordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit
import RxSwift

final class DashboardCoordinator: Coordinator {

    enum Route {
        case setting
        case about
        case taskEdit
        case customTask(task: DailyTask)
        case iconChooser
        case villagerDetail(villager: Villager)
        case npcDetail(npc: NPC)
        case progress
        case item(category: Category)
        case itemDetail(item: Item)
        case keyword(title: String, keyword: Keyword)
        case pop
        case dismiss
    }

    let type: CoordinatorType = .dashboard
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UINavigationController!
    private(set) var parentCoordinator: Coordinator?

    weak var delegate: CustomTaskViewControllerDelegate?

    init(rootViewController: UINavigationController = UINavigationController()) {
        self.rootViewController = rootViewController
    }

    private var settingsObserver: NSObjectProtocol?

    func start() {
        let viewController = DashboardViewController()
        viewController.bind(to: DashboardReactor(coordinator: self))
        viewController.setUpViewModels(
            userInfoVM: UserInfoReactor(coordinator: self),
            tasksVM: TodaysTasksSectionReactor(coordinator: self),
            villagersVM: VillagersSectionReactor(coordinator: self),
            progressVM: CollectionProgressSectionReactor(coordinator: self),
            fixeVisitdNPCListVM: NpcsSectionReactor(state: .init(), mode: .fixedVisit, coordinator: self),
            randomVisitNPCListVM: NpcsSectionReactor(state: .init(), mode: .randomVisit, coordinator: self)
        )
        rootViewController.addChild(viewController)

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openSettingsFromKeyboard,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.transition(for: .setting)
        }
    }

    func transition(for route: Route) {
        switch route {
        case .setting:
            let viewController = PreferencesViewController()
            viewController.bind(
                to: PreferencesReactor(coordinator: self),
                appSettingReactor: AppSettingReactor(coordinator: self)
            )
            presentAdaptive(viewController, from: rootViewController)

        case .about:
            let viewController = AboutViewController()
            viewController.bind(to: AboutReactor(coordinator: self))
            presentAdaptive(viewController, from: rootViewController)

        case .taskEdit:
            let viewController = TaskEditViewController()
            viewController.bind(to: TasksEditReactor(coordinator: self))
            presentAdaptive(viewController, from: rootViewController)

        case .customTask(let task):
            let viewController = CustomTaskViewController()
            delegate = viewController
            if task.icon == "plus" {
                viewController.bind(to: CustomTaskReactor(coordinator: self, task: nil))
                viewController.mode = .add
            } else {
                viewController.bind(to: CustomTaskReactor(coordinator: self, task: task))
                viewController.mode = .edit
            }
            let navigationController = rootViewController.visibleViewController?.navigationController as? UINavigationController
            navigationController?.pushViewController(viewController, animated: true)

        case .iconChooser:
            let viewController = IconChooserViewController()
            viewController.coordinator = self
            let source = rootViewController.visibleViewController ?? rootViewController!
            presentAdaptive(viewController, from: source, preferredSize: CGSize(width: 400, height: 500))

        case .villagerDetail(let villager):
            let viewController = VillagerDetailViewController()
            viewController.bind(
                to: VillagerDetailReactor(villager: villager, state: .init(villager: villager))
            )
            presentAdaptive(viewController, from: rootViewController)
            HapticManager.shared.notification(type: .success)

        case let .npcDetail(npc):
            let viewController = NPCDetailViewController()
            viewController.bind(
                to: NPCDetailReactor(npc: npc, state: .init(npc: npc))
            )
            presentAdaptive(viewController, from: rootViewController)
            HapticManager.shared.notification(type: .success)

        case .progress:
            let viewController = CollectionProgressViewController()
            viewController.bind(to: CollectionProgressReactor(coordinator: self))
            rootViewController.pushViewController(viewController, animated: true)

        case .item(let category):
            let viewController = ItemsViewController()
            let currentMonth = (Calendar.current.dateComponents([.month], from: Date()).month ?? 1).description
            viewController.bind(
                to: ItemsReactor(category: category, coordinator: self),
                keyword: [.month: currentMonth]
            )
            rootViewController.pushViewController(viewController, animated: true)

        case .itemDetail(let item):
            let viewController = ItemDetailViewController()
            viewController.bind(to: ItemDetailReactor(item: item, coordinator: self))
            rootViewController.pushViewController(viewController, animated: true)

        case .keyword(let title, let keyword):
            let viewController = ItemsViewController()
            viewController.bind(to: ItemsReactor(coordinator: self, mode: .keyword(title: title, category: keyword)))
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

    func setUpParent(to coordinator: Coordinator) {
        parentCoordinator = coordinator
    }

    func showAlert(title: String, message: String) -> Observable<Bool> {
        guard let currentVC = rootViewController.visibleViewController else {
            return .empty()
        }
        return currentVC.showAlert(title: title, message: message)
    }

    // TEMPORARY: Recovery
    func showRecoveryResultAlert(success: Bool, message: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let currentVC = self?.rootViewController.visibleViewController else { return }
            let title: String
            let body: String
            if success {
                title = "Recovery Complete".localized
                body = "Please restart the app to complete data recovery from iCloud.".localized
            } else {
                title = "Recovery Failed".localized
                body = message ?? "Unknown error".localized
            }
            let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { _ in
                if success {
                    exit(0)
                }
            })
            currentVC.present(alert, animated: true)
        }
    }
}

protocol CustomTaskViewControllerDelegate: AnyObject {
    func selectedIcon(_ icon: String)
}
