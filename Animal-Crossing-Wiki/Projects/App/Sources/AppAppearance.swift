//
//  AppAppearance.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit
import ACNHCore
import ACNHShared

final class AppAppearance {
    static func setUpAppearance() {
        UITabBar.appearance().tintColor = .acText
        UITabBar.appearance().unselectedItemTintColor = .acText.withAlphaComponent(0.6)
        UITabBar.appearance().backgroundColor = .acBackground
        UITabBar.appearance().barTintColor = .acBackground
        UIBarButtonItem.appearance().tintColor = .acText
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().barTintColor = .acBackground
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.acText]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.acText]
    }
}
