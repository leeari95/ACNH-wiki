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
        UITabBar.appearance().unselectedItemTintColor = .acTabBarTint.withAlphaComponent(0.7)
        UITabBar.appearance().backgroundColor = .acTabBarBackground
        UITabBar.appearance().barTintColor = .acTabBarBackground
        UIBarButtonItem.appearance().tintColor = .acText
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().barTintColor = .acNavigationBarBackground
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.acText]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.acText]
    }
}
