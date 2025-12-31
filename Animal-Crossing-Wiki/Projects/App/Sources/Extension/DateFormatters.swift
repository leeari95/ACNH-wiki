//
//  DateFormatters.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import Foundation

/// DateFormatter 인스턴스를 캐싱하여 성능을 최적화하는 유틸리티
/// DateFormatter 생성은 비용이 높은 작업이므로 static lazy 프로퍼티로 캐싱합니다.
enum DateFormatters {

    // MARK: - Dashboard

    /// 대시보드용 날짜 포맷터 (예: "Thursday, Jan 1")
    static let dashboardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return formatter
    }()

    // MARK: - Calendar

    /// 월 숫자 포맷터 (예: "01", "12")
    static let monthNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return formatter
    }()

    /// 월 이름 접근용 포맷터
    static let monthSymbols: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
}
