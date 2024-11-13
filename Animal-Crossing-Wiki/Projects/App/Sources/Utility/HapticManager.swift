//
//  HapticManager.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import UIKit

final class HapticManager {

    enum Mode {
        case on
        case off
    }

    static let shared = HapticManager()
    private(set) var mode: Mode
    private let impactGenerator: UIImpactFeedbackGenerator
    private let selectionGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator

    private init() {
        self.impactGenerator = UIImpactFeedbackGenerator()
        self.selectionGenerator = UISelectionFeedbackGenerator()
        self.notificationGenerator = UINotificationFeedbackGenerator()
        impactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        if let state = UserDefaults.standard.object(forKey: "hapticState") as? Bool {
            self.mode = state ? .on : .off
        } else {
            self.mode = .on
            UserDefaults.standard.set(true, forKey: "hapticState")
        }
    }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard mode == .on else {
            return
        }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func selection() {
        guard mode == .on else {
            return
        }
        selectionGenerator.selectionChanged()
    }

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard mode == .on else {
            return
        }
        notificationGenerator.notificationOccurred(type)
    }

    func toggle() {
        mode = mode == .on ? .off : .on
        UserDefaults.standard.set(mode == .off ? false : true, forKey: "hapticState")
    }
}
