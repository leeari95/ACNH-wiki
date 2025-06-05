//
//  UIButton+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit
import Kingfisher

public extension UIButton {
    public func setImage(with urlString: String) {
        ImageCache.default.retrieveImage(forKey: urlString) { result in
            if let image = try? result.get().image?.withRenderingMode(.alwaysOriginal) {
                self.setImage(image, for: .normal)
            } else {
                public let url = URL(string: urlString)
                self.kf.setImage(with: url, for: .normal)
            }
        }
    }
}
