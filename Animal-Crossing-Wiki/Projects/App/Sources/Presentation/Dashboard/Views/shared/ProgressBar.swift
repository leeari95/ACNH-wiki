//
//  ProgressBar.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit
import ACNHCore
import ACNHShared

final class ProgressBar: UIProgressView {
    private var height: CGFloat = 10

    override var intrinsicContentSize: CGSize {
        return CGSize(width: -1.0, height: height)
    }

    convenience init(height: CGFloat) {
        self.init(frame: .zero)
        self.height = height
    }

    func setHeight(_ height: CGFloat) {
        self.height = height
        setUpCornerRadius()
    }

    private func setUpCornerRadius() {
        let radius = layer.bounds.height * 1.5
        layer.cornerRadius = radius
        clipsToBounds = true
        layer.sublayers?.forEach({ layer in
            layer.cornerRadius = radius
        })
        subviews.forEach { view in
            view.clipsToBounds = true
        }
        tintColor = .acHeaderBackground
    }
}
