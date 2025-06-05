//
//  UIFont+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

public extension UIFont {
    static func preferredFont(for style: TextStyle, weight: Weight) -> UIFont {
        public let metrics = UIFontMetrics(forTextStyle: style)
        public let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        public let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
}
