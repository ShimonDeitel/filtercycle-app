import XCTest
@testable import Filtercycle

final class FilterStatusTests: XCTestCase {

    // MARK: - FilterStatus.status(daysRemaining:intervalDays:) thresholds

    func test_fresh_wellAboveThreshold() {
        // 90-day interval, 50 remaining -> 55.5% remaining -> Fresh
        XCTAssertEqual(FilterStatus.status(daysRemaining: 50, intervalDays: 90), .fresh)
    }

    func test_fresh_justAboveTwentyFivePercent() {
        // 90-day interval: 25% = 22.5 days. 23 remaining -> 25.5% -> Fresh
        XCTAssertEqual(FilterStatus.status(daysRemaining: 23, intervalDays: 90), .fresh)
    }

    func test_dueSoon_exactlyTwentyFivePercent() {
        // 90-day interval: exactly 25% = 22.5, use 20/80 = 25% exactly.
        XCTAssertEqual(FilterStatus.status(daysRemaining: 20, intervalDays: 80), .dueSoon)
    }

    func test_dueSoon_justBelowTwentyFivePercent() {
        XCTAssertEqual(FilterStatus.status(daysRemaining: 19, intervalDays: 80), .dueSoon)
    }

    func test_dueSoon_atZeroRemaining_dueToday() {
        XCTAssertEqual(FilterStatus.status(daysRemaining: 0, intervalDays: 90), .dueSoon)
    }

    func test_overdue_oneDayPast() {
        XCTAssertEqual(FilterStatus.status(daysRemaining: -1, intervalDays: 90), .overdue)
    }

    func test_overdue_farPast() {
        XCTAssertEqual(FilterStatus.status(daysRemaining: -500, intervalDays: 90), .overdue)
    }

    func test_zeroIntervalDays_treatedAsOverdue_avoidsDivideByZero() {
        XCTAssertEqual(FilterStatus.status(daysRemaining: 0, intervalDays: 0), .overdue)
        XCTAssertEqual(FilterStatus.status(daysRemaining: 5, intervalDays: 0), .overdue)
    }

    // MARK: - Filter.daysSinceChanged / daysRemaining / status across categories

    private func makeFilter(category: FilterCategory, daysAgo: Int, now: Date, calendar: Calendar) -> Filter {
        let lastChanged = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return Filter(name: "Test", category: category, lastChangedDate: lastChanged)
    }

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    func test_hvac_defaultInterval90_freshAt10DaysIn() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        let filter = makeFilter(category: .hvac, daysAgo: 10, now: now, calendar: cal)
        XCTAssertEqual(filter.intervalDays, 90)
        XCTAssertEqual(filter.daysSinceChanged(now: now, calendar: cal), 10)
        XCTAssertEqual(filter.daysRemaining(now: now, calendar: cal), 80)
        XCTAssertEqual(filter.status(now: now, calendar: cal), .fresh)
    }

    func test_fridgeWater_defaultInterval180_dueSoonNear165Days() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        // 180 * 0.75 = 135 days elapsed marks the fresh/due-soon boundary.
        let filter = makeFilter(category: .fridgeWater, daysAgo: 140, now: now, calendar: cal)
        XCTAssertEqual(filter.intervalDays, 180)
        XCTAssertEqual(filter.daysRemaining(now: now, calendar: cal), 40)
        XCTAssertEqual(filter.status(now: now, calendar: cal), .dueSoon)
    }

    func test_humidifier_defaultInterval45_overdueAt50Days() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        let filter = makeFilter(category: .humidifier, daysAgo: 50, now: now, calendar: cal)
        XCTAssertEqual(filter.intervalDays, 45)
        XCTAssertEqual(filter.daysRemaining(now: now, calendar: cal), -5)
        XCTAssertEqual(filter.status(now: now, calendar: cal), .overdue)
    }

    func test_vacuum_defaultInterval60() {
        XCTAssertEqual(FilterCategory.vacuum.defaultIntervalDays, 60)
    }

    func test_rangeHood_defaultInterval120() {
        XCTAssertEqual(FilterCategory.rangeHood.defaultIntervalDays, 120)
    }

    func test_custom_usesUserSuppliedInterval_notDefault() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        let lastChanged = cal.date(byAdding: .day, value: -10, to: now)!
        let filter = Filter(name: "Weird Filter", category: .custom, intervalDays: 30, lastChangedDate: lastChanged)
        XCTAssertEqual(filter.intervalDays, 30)
        XCTAssertEqual(filter.daysRemaining(now: now, calendar: cal), 20)
    }

    func test_futureLastChangedDate_clampsDaysSinceChangedToZero() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        let future = cal.date(byAdding: .day, value: 5, to: now)!
        let filter = Filter(name: "Future", category: .hvac, lastChangedDate: future)
        XCTAssertEqual(filter.daysSinceChanged(now: now, calendar: cal), 0)
        XCTAssertEqual(filter.daysRemaining(now: now, calendar: cal), 90)
        XCTAssertEqual(filter.status(now: now, calendar: cal), .fresh)
    }

    func test_elapsedFraction_matchesDaysSinceChangedOverInterval() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        let filter = makeFilter(category: .hvac, daysAgo: 45, now: now, calendar: cal)
        XCTAssertEqual(filter.elapsedFraction(now: now, calendar: cal), 0.5, accuracy: 0.0001)
    }

    func test_elapsedFraction_canExceedOneWhenOverdue() {
        let cal = utcCalendar
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
        let filter = makeFilter(category: .humidifier, daysAgo: 90, now: now, calendar: cal) // 2x the 45-day interval
        XCTAssertEqual(filter.elapsedFraction(now: now, calendar: cal), 2.0, accuracy: 0.0001)
    }
}
