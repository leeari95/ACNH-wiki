//
//  UIColor+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

extension UIColor {
    class var acTabBarTint: UIColor {
        return UIColor(named: "ACTabBarTint") ?? .label
    }
    
    class var acTabBarBackground: UIColor {
        return UIColor(named: "ACTabBarBackground") ?? .clear
    }
    
    class var acHeaderBackground: UIColor {
        return UIColor(named: "ACHeaderBackground") ?? .clear
    }
    
    class var acHeaderText: UIColor {
        return UIColor(named: "ACHeaderText") ?? .label
    }
    
    class var acBackground: UIColor {
        return UIColor(named: "ACBackground") ?? .clear
    }
    
    class var acSecondaryBackground: UIColor {
        return UIColor(named: "ACSecondaryBackground") ?? .clear
    }
    
    class var acTertiaryBackground: UIColor {
        return UIColor(named: "ACTertiaryBackground") ?? .clear
    }
    
    class var acText: UIColor {
        return UIColor(named: "ACText") ?? .label
    }
    
    class var acSecondaryText: UIColor {
        return UIColor(named: "ACSecondaryText") ?? .systemGray
    }
}
