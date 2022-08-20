//
//  LoadingView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/19.
//

import UIKit

class LoadingView: UIActivityIndicatorView {
    
    convenience init(backgroundColor: UIColor, alpha: CGFloat) {
        self.init(frame: .zero)
        self.style = UIActivityIndicatorView.Style.large
        self.backgroundColor = backgroundColor
        self.alpha = alpha
    }
}
