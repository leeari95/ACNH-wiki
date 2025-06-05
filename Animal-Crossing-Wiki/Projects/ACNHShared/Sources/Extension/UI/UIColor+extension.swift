//
//  UIColor+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

public extension UIColor {
    public class var acHeaderBackground: UIColor {
        return UIColor(named: "ACHeaderBackground") ?? .clear
    }

    public class var acBackground: UIColor {
        return UIColor(named: "ACBackground") ?? .clear
    }

    public class var acSecondaryBackground: UIColor {
        return UIColor(named: "ACSecondaryBackground") ?? .clear
    }

    public class var acText: UIColor {
        return UIColor(named: "ACText") ?? .label
    }

    public class var acSecondaryText: UIColor {
        return UIColor(named: "ACSecondaryText") ?? .systemGray
    }

    public class var acNavigationBarTint: UIColor {
        return UIColor(named: "ACNavigationBarTint") ?? .clear
    }

    public class var catalogBar: UIColor {
        return UIColor(named: "catalog-bar") ?? .clear
    }

    public class var catalogBackground: UIColor {
        return UIColor(named: "catalog-background") ?? .clear
    }

    public class var catalogSelected: UIColor {
        return UIColor(named: "catalog-selected") ?? .clear
    }

    public class var acTabBarTint: UIColor {
        return UIColor(named: "catalog-text") ?? .label
    }
}
