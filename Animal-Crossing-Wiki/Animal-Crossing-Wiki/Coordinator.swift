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
        for (index, coordinator) in childCoordinators.enumerated() where child?.type == coordinator.type {
            childCoordinators.remove(at: index)
        }
    }
}

enum CoordinatorType {
    case main
    case dashboard
    case taskEdit
}
