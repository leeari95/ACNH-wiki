//
//  UIView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }
}
