//
//  UIColor+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

extension UIColor {
    class var acHeaderBackground: UIColor {
        return UIColor(named: "ACHeaderBackground") ?? .clear
    }

    class var acBackground: UIColor {
        return UIColor(named: "ACBackground") ?? .clear
    }

    class var acSecondaryBackground: UIColor {
        return UIColor(named: "ACSecondaryBackground") ?? .clear
    }

    class var acText: UIColor {
        return UIColor(named: "ACText") ?? .label
    }

    class var acSecondaryText: UIColor {
        return UIColor(named: "ACSecondaryText") ?? .systemGray
    }

    class var acNavigationBarTint: UIColor {
        return UIColor(named: "ACNavigationBarTint") ?? .clear
    }

    class var catalogBar: UIColor {
        return UIColor(named: "catalog-bar") ?? .clear
    }

    class var catalogBackground: UIColor {
        return UIColor(named: "catalog-background") ?? .clear
    }

    class var catalogSelected: UIColor {
        return UIColor(named: "catalog-selected") ?? .clear
    }

    class var acTabBarTint: UIColor {
        return UIColor(named: "catalog-text") ?? .label
    }
}
