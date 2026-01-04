//
//  DateFormatters.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import Foundation

/// DateFormatter 인스턴스를 캐싱하여 성능을 최적화하는 유틸리티
///
/// DateFormatter 생성은 비용이 높은 작업이므로 static 프로퍼티로 캐싱합니다.
/// 각 포맷터는 읽기 전용으로 사용되며, dateFormat을 변경하지 않아 스레드 안전합니다.
///
/// - Note: 월 관련 정보가 필요한 경우 `Calendar.current.component(_:from:)` 또는
///         `Calendar.current.monthSymbols`를 직접 사용하세요.
enum DateFormatters {

    // MARK: - Dashboard

    /// 대시보드용 날짜 포맷터 (예: "Thursday, Jan 1")
    ///
    /// - Note: 읽기 전용으로 사용하며, 스레드 안전합니다.
    static let dashboardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return formatter
    }()
}
