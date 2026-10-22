import XCTest
import SwiftUI
import TitanLocalization
@testable import TitanDesignSystem

final class DateDisplayTests: XCTestCase {
    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testDecember2024StartingSunday() {
        // Figma's calendar: 1 December 2024 is a Sunday, the grid ends with 1–4 January.
        let cal = calendar(firstWeekday: 1)
        let days = TKCalendarGrid.days(in: date(2024, 12, 10, in: cal), calendar: cal)
        XCTAssertEqual(days.count, 35)
        XCTAssertEqual(days.first?.date, date(2024, 12, 1, in: cal))
        XCTAssertEqual(days.filter(\.isInMonth).count, 31)
        XCTAssertEqual(days.last?.date, date(2025, 1, 4, in: cal))
        XCTAssertFalse(days.last!.isInMonth)
    }

    func testDecember2024StartingMonday() {
        // Figma's "Date Expand": the grid starts on Monday 25 November.
        let cal = calendar(firstWeekday: 2)
        let days = TKCalendarGrid.days(in: date(2024, 12, 1, in: cal), calendar: cal)
        XCTAssertEqual(days.count, 42)
        XCTAssertEqual(days.first?.date, date(2024, 11, 25, in: cal))
        XCTAssertFalse(days.first!.isInMonth)
        XCTAssertEqual(days[6].date, date(2024, 12, 1, in: cal))
        XCTAssertTrue(days[6].isInMonth)
    }

    func testWeekdaySymbolsFollowFirstWeekday() {
        XCTAssertEqual(TKCalendarGrid.weekdaySymbols(calendar: calendar(firstWeekday: 1)).first, "Sun")
        XCTAssertEqual(TKCalendarGrid.weekdaySymbols(calendar: calendar(firstWeekday: 2)), ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    }

    func testWeekContainingDate() {
        let cal = calendar(firstWeekday: 2)
        let week = TKCalendarGrid.week(containing: date(2024, 12, 22, in: cal), calendar: cal)
        XCTAssertEqual(week.first, date(2024, 12, 16, in: cal))
        XCTAssertEqual(week.last, date(2024, 12, 22, in: cal))
    }

    func testProgressRing() {
        XCTAssertEqual(TKProgressRing<EmptyView>.clamped(-1), 0)
        XCTAssertEqual(TKProgressRing<EmptyView>.clamped(0.3), 0.3)
        XCTAssertEqual(TKProgressRing<EmptyView>.clamped(2), 1)
        XCTAssertEqual(TKProgressRing<EmptyView>.clamped(.nan), 0)
        XCTAssertEqual(TKProgressRing<EmptyView>.lineWidth(for: 42), 3.15, accuracy: 0.001)
    }

    func testPeriodStringsExistInBothLanguages() {
        for key in [KitStrings.previous, KitStrings.next] {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}
