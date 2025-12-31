//
//  WidgetBackground+Extension.swift
//  ACNHWidget
//
//  Created by Claude on 2025/01/01.
//

import SwiftUI
import WidgetKit

// MARK: - iOS 16 Compatibility

/// iOS 16과 iOS 17+ 모두에서 위젯 배경을 처리하는 View Extension
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(uiColor: .tertiarySystemBackground))
        }
    }
}
