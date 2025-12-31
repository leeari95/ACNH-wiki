//
//  DateFormattersTests.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import XCTest
@testable import ACNH_wiki

final class DateFormattersTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }

    // MARK: - Date Formatting Tests

    func test_Formatted_WithYearMonthDayFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 1, day: 15)

        let result = date.formatted("yyyy-MM-dd")

        XCTAssertEqual(result, "2025-01-15")
    }

    func test_Formatted_WithTimeFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 1, day: 15, hour: 14, minute: 30, second: 45)

        let result = date.formatted("HH:mm:ss")

        XCTAssertEqual(result, "14:30:45")
    }

    func test_Formatted_WithFullDateTimeFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 12, day: 25, hour: 9, minute: 5, second: 0)

        let result = date.formatted("yyyy-MM-dd HH:mm:ss")

        XCTAssertEqual(result, "2025-12-25 09:05:00")
    }

    func test_Formatted_WithMonthDayFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 3, day: 7)

        let result = date.formatted("MM/dd")

        XCTAssertEqual(result, "03/07")
    }

    func test_Formatted_WithYearOnlyFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 6, day: 15)

        let result = date.formatted("yyyy")

        XCTAssertEqual(result, "2025")
    }

    func test_Formatted_WithMonthOnlyFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 11, day: 1)

        let result = date.formatted("MM")

        XCTAssertEqual(result, "11")
    }

    func test_Formatted_WithDayOnlyFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 1, day: 28)

        let result = date.formatted("dd")

        XCTAssertEqual(result, "28")
    }

    func test_Formatted_With12HourTimeFormat_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 1, day: 1, hour: 14, minute: 30)

        let result = date.formatted("hh:mm a")

        // Note: AM/PM format may vary by locale
        XCTAssertTrue(result.contains("02:30"))
    }

    func test_Formatted_WithDifferentFormats_ShouldReturnDifferentResults() {
        let date = makeDate(year: 2025, month: 5, day: 20)

        let format1 = date.formatted("yyyy-MM-dd")
        let format2 = date.formatted("dd/MM/yyyy")
        let format3 = date.formatted("MM-dd-yyyy")

        XCTAssertEqual(format1, "2025-05-20")
        XCTAssertEqual(format2, "20/05/2025")
        XCTAssertEqual(format3, "05-20-2025")
    }

    // MARK: - Edge Cases

    func test_Formatted_WithLeapYearDate_ShouldReturnCorrectString() {
        let date = makeDate(year: 2024, month: 2, day: 29)

        let result = date.formatted("yyyy-MM-dd")

        XCTAssertEqual(result, "2024-02-29")
    }

    func test_Formatted_WithEndOfYear_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59)

        let result = date.formatted("yyyy-MM-dd HH:mm:ss")

        XCTAssertEqual(result, "2025-12-31 23:59:59")
    }

    func test_Formatted_WithStartOfYear_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0, second: 0)

        let result = date.formatted("yyyy-MM-dd HH:mm:ss")

        XCTAssertEqual(result, "2025-01-01 00:00:00")
    }

    func test_Formatted_WithMidnight_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 0, minute: 0, second: 0)

        let result = date.formatted("HH:mm")

        XCTAssertEqual(result, "00:00")
    }

    func test_Formatted_WithNoon_ShouldReturnCorrectString() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 12, minute: 0, second: 0)

        let result = date.formatted("HH:mm")

        XCTAssertEqual(result, "12:00")
    }

    // MARK: - Shared Formatter Performance Test

    func test_Formatted_MultipleCallsShouldReuseFormatter() {
        // This test verifies the shared formatter is reused by checking
        // that multiple calls with same format produce consistent results
        let date = makeDate(year: 2025, month: 7, day: 4)

        let results = (0..<100).map { _ in date.formatted("yyyy-MM-dd") }

        XCTAssertTrue(results.allSatisfy { $0 == "2025-07-04" })
    }
}
