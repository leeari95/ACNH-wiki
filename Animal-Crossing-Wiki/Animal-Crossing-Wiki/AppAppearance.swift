//
//  AppAppearance.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

final class AppAppearance {
    static func setUpAppearance() {
        UITabBar.appearance().tintColor = .acTabBarTint
        UITabBar.appearance().unselectedItemTintColor = .acText
        UITabBar.appearance().backgroundColor = .acTabBarBackground
        UIBarButtonItem.appearance().tintColor = .acText
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.acText]
    }
}
