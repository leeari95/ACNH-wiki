//
//  Coordinator.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import Foundation

protocol Coordinator: AnyObject {
    var childCoordinators : [Coordinator] { get set }
    func start()
}
