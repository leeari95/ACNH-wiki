//
//  HapticManager.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import UIKit

final class HapticManager {
    
    static let shared = HapticManager()
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
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func selection() {
        selectionGenerator.selectionChanged()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
}
