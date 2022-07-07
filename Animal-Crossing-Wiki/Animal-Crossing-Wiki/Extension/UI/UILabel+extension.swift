//
//  UILabel+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import UIKit

extension UILabel {
    convenience init(text: String, font: UIFont, color: UIColor = .label) {
        self.init(frame: .zero)
        self.text = text
        self.font = font
        self.textColor = color
    }
}
