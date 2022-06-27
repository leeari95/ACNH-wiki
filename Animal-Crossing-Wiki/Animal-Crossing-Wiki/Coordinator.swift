//
//  Coordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import Foundation

protocol Coordinator: AnyObject {
    var type: CoordinatorType { get }
    var childCoordinators : [Coordinator] { get set }
    func start()
    func childDidFinish(_ child: Coordinator?)
}

extension Coordinator {
    func childDidFinish(_ child: Coordinator?) {
        _ = childCoordinators.firstIndex(where: { $0.type == child?.type })
            .flatMap { childCoordinators.remove(at: $0) }
    }
}

enum CoordinatorType {
    case main
    case dashboard
    case taskEdit
}
