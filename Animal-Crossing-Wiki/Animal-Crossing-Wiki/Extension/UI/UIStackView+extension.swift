//
//  UIStackView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

extension UIStackView {
    
    convenience init(
        axis: NSLayoutConstraint.Axis,
        alignmnet: UIStackView.Alignment,
        distribution: UIStackView.Distribution,
        spacing: CGFloat
    ) {
        self.init(frame: .zero)
        self.axis = axis
        self.alignment = alignmnet
        self.distribution = distribution
        self.spacing = spacing
    }
    
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addArrangedSubview(view)
        }
    }
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addArrangedSubview(view)
        }
    }
}
