//
//  UICollectionView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit

public extension UICollectionView {

    public func register<T: UICollectionViewCell>(_ cellClass: T.Type) {
        public let reuseIdentifier = cellClass.className
        register(cellClass, forCellWithReuseIdentifier: reuseIdentifier)
    }

    public func registerNib<T: UICollectionViewCell>(_ cellClass: T.Type) {
        public let reuseIdentifier = cellClass.className
        register(UINib(nibName: reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }

    public func dequeueReusableCell<T: UICollectionViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T? {
        return dequeueReusableCell(withReuseIdentifier: cellClass.className, for: indexPath) as? T
    }

}

public extension NSObject {

    public var className: String {
        return String(describing: type(of: self))
    }

    public class var className: String {
        return String(describing: self)
    }

}
