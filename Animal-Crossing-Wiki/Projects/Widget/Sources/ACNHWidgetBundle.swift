//
//  ACNHWidgetBundle.swift
//  ACNHWidget
//
//  Created by Claude on 2025/01/01.
//

import WidgetKit
import SwiftUI

/// ACNH Wiki 위젯 번들
/// 앱에서 제공하는 모든 위젯을 이 번들에 등록합니다.
@main
struct ACNHWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyTaskWidget()
        CollectionProgressWidget()
    }
}
