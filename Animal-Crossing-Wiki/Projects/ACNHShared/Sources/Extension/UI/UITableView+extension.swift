//
//  UITableView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/08.
//

import UIKit

public extension UITableView {

    public func register<T: UITableViewCell>(_ cellClass: T.Type) {
        public let reuseIdentifier = cellClass.className
        register(cellClass, forCellReuseIdentifier: reuseIdentifier)
    }

    public func registerNib<T: UITableViewCell>(_ cellClass: T.Type) {
        public let reuseIdentifier = cellClass.className
        register(UINib(nibName: reuseIdentifier, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
    }

}
