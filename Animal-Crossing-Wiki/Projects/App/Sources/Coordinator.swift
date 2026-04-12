//
//  Coordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

protocol Coordinator: AnyObject {
    var type: CoordinatorType { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
    func childDidFinish(_ child: Coordinator?)
}

extension Coordinator {
    func childDidFinish(_ child: Coordinator?) {
        _ = childCoordinators.firstIndex(where: { $0.type == child?.type })
            .flatMap { childCoordinators.remove(at: $0) }
    }

    func presentAdaptive(
        _ viewController: UIViewController,
        from source: UIViewController,
        preferredSize: CGSize = CGSize(width: 540, height: 620)
    ) {
        let nav = UINavigationController(rootViewController: viewController)
        if source.traitCollection.horizontalSizeClass == .regular {
            nav.modalPresentationStyle = .formSheet
            nav.preferredContentSize = preferredSize
        }
        source.present(nav, animated: true)
    }
}

enum CoordinatorType {
    case main
    case dashboard
    case taskEdit
    case animals
    case catalog
    case collection
    case turnipPrices
}
