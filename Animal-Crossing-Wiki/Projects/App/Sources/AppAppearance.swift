//
//  AppAppearance.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

final class AppAppearance {
    static func setUpAppearance() {
        UITabBar.appearance().tintColor = .acText
        UITabBar.appearance().unselectedItemTintColor = .acText.withAlphaComponent(0.6)
        UIBarButtonItem.appearance().tintColor = .acText
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.acText]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.acText]
    }
}
