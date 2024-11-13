//
//  UICollectionView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit

extension UICollectionView {

    func register<T: UICollectionViewCell>(_ cellClass: T.Type) {
        let reuseIdentifier = cellClass.className
        register(cellClass, forCellWithReuseIdentifier: reuseIdentifier)
    }

    func registerNib<T: UICollectionViewCell>(_ cellClass: T.Type) {
        let reuseIdentifier = cellClass.className
        register(UINib(nibName: reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T? {
        return dequeueReusableCell(withReuseIdentifier: cellClass.className, for: indexPath) as? T
    }

}

extension NSObject {

    var className: String {
        return String(describing: type(of: self))
    }

    class var className: String {
        return String(describing: self)
    }

}
