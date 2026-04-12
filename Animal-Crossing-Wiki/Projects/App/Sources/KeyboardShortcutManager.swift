//
//  KeyboardShortcutManager.swift
//  Animal-Crossing-Wiki
//

import UIKit

final class KeyboardShortcutManager {

    static func buildKeyCommands(for tabBarController: UITabBarController) -> [UIKeyCommand] {
        var commands: [UIKeyCommand] = []

        // Tab switching: Cmd+1~5
        let tabTitles = [
            "Dashboard".localized,
            "Catalog".localized,
            "animals".localized,
            "turnipPrices".localized,
            "Collection".localized
        ]
        for (index, title) in tabTitles.enumerated() {
            let command = UIKeyCommand(
                title: title,
                action: #selector(KeyboardResponderTabBarController.selectTabByKeyCommand(_:)),
                input: "\(index + 1)",
                modifierFlags: .command,
                propertyList: index
            )
            command.discoverabilityTitle = title
            commands.append(command)
        }

        // Search: Cmd+F
        let searchCommand = UIKeyCommand(
            title: "Search".localized,
            action: #selector(KeyboardResponderTabBarController.activateSearch),
            input: "f",
            modifierFlags: .command
        )
        searchCommand.discoverabilityTitle = "Search".localized
        commands.append(searchCommand)

        // Settings: Cmd+,
        let settingsCommand = UIKeyCommand(
            title: "Settings".localized,
            action: #selector(KeyboardResponderTabBarController.openSettings),
            input: ",",
            modifierFlags: .command
        )
        settingsCommand.discoverabilityTitle = "Settings".localized
        commands.append(settingsCommand)

        // Music: Space to play/pause
        let playPauseCommand = UIKeyCommand(
            title: "Play/Pause".localized,
            action: #selector(KeyboardResponderTabBarController.togglePlayPause),
            input: " ",
            modifierFlags: []
        )
        playPauseCommand.discoverabilityTitle = "Play/Pause".localized
        commands.append(playPauseCommand)

        return commands
    }
}

class KeyboardResponderTabBarController: UITabBarController {

    override var keyCommands: [UIKeyCommand]? {
        return KeyboardShortcutManager.buildKeyCommands(for: self)
    }

    override var canBecomeFirstResponder: Bool { true }

    @objc func selectTabByKeyCommand(_ sender: UIKeyCommand) {
        guard let index = sender.propertyList as? Int,
              index < (viewControllers?.count ?? 0) else {
            return
        }
        selectedIndex = index
    }

    @objc func activateSearch() {
        guard let navController = selectedViewController as? UINavigationController,
              let topVC = navController.topViewController else {
            return
        }
        topVC.navigationItem.searchController?.searchBar.becomeFirstResponder()
    }

    @objc func openSettings() {
        // Post notification for DashboardCoordinator to handle
        NotificationCenter.default.post(name: .openSettingsFromKeyboard, object: nil)
    }

    @objc func togglePlayPause() {
        MusicPlayerManager.shared.togglePlaying()
    }
}

extension Notification.Name {
    static let openSettingsFromKeyboard = Notification.Name("openSettingsFromKeyboard")
}
