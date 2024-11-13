//
//  UITableView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/08.
//

import UIKit

extension UITableView {

    func register<T: UITableViewCell>(_ cellClass: T.Type) {
        let reuseIdentifier = cellClass.className
        register(cellClass, forCellReuseIdentifier: reuseIdentifier)
    }

    func registerNib<T: UITableViewCell>(_ cellClass: T.Type) {
        let reuseIdentifier = cellClass.className
        register(UINib(nibName: reuseIdentifier, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
    }

}
