import XCTest
@testable import Filtercycle

final class RateLimiterTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        // Fix "now" mid-month so we're not near a boundary unintentionally.
        now = date(2026, 7, 15)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = h
        return calendar.date(from: comps)!
    }

    // MARK: - Empty / basic

    func test_emptyLogs_fullQuotaRemaining() {
        let remaining = RateLimiter.remainingLogsThisMonth(existingLogs: [], now: now, calendar: calendar)
        XCTAssertEqual(remaining, 5)
        XCTAssertTrue(RateLimiter.canLogChange(existingLogs: [], now: now, calendar: calendar))
    }

    func test_fourLogsThisMonth_oneRemaining() {
        let logs = (0..<4).map { date(2026, 7, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: calendar), 1)
        XCTAssertTrue(RateLimiter.canLogChange(existingLogs: logs, now: now, calendar: calendar))
    }

    // MARK: - Exact boundary: 5th allowed, 6th blocked

    func test_fifthLog_isAllowed() {
        // 4 existing logs -> the 5th log is still allowed (remaining > 0 before it).
        let logs = (0..<4).map { date(2026, 7, 1 + $0) }
        XCTAssertTrue(RateLimiter.canLogChange(existingLogs: logs, now: now, calendar: calendar))
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: calendar), 1)
    }

    func test_sixthLog_isBlocked() {
        // 5 existing logs this month -> quota exhausted, 6th blocked.
        let logs = (0..<5).map { date(2026, 7, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: calendar), 0)
        XCTAssertFalse(RateLimiter.canLogChange(existingLogs: logs, now: now, calendar: calendar))
    }

    func test_moreThanFiveLogsSomehow_neverNegativeRemaining() {
        let logs = (0..<9).map { date(2026, 7, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: calendar), 0)
        XCTAssertFalse(RateLimiter.canLogChange(existingLogs: logs, now: now, calendar: calendar))
    }

    // MARK: - Previous-month logs excluded

    func test_previousMonthLogs_areExcludedFromCount() {
        let juneLogs = (0..<5).map { date(2026, 6, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: juneLogs, now: now, calendar: calendar), 5)
        XCTAssertTrue(RateLimiter.canLogChange(existingLogs: juneLogs, now: now, calendar: calendar))
    }

    func test_mixedMonthLogs_onlyCurrentMonthCounted() {
        let logs = [date(2026, 6, 28), date(2026, 6, 29), date(2026, 6, 30)] + [date(2026, 7, 1), date(2026, 7, 2)]
        // Only 2 logs are in July (now's month).
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: calendar), 3)
    }

    func test_sameMonthAcrossDifferentYears_notConflated() {
        // 5 logs in July 2025 should not count against July 2026.
        let logs2025 = (0..<5).map { date(2025, 7, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs2025, now: now, calendar: calendar), 5)
    }

    // MARK: - Logs on the 1st of the month

    func test_logOnFirstOfMonth_countsTowardThatMonth() {
        let nowOnFirst = date(2026, 7, 1, 23)
        let logs = [date(2026, 7, 1, 0)]
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: nowOnFirst, calendar: calendar), 4)
    }

    func test_logOnLastDayOfPreviousMonth_doesNotCountForFirstOfNextMonth() {
        let nowOnFirst = date(2026, 7, 1, 0)
        let juneLog = date(2026, 6, 30, 23)
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: [juneLog], now: nowOnFirst, calendar: calendar), 5)
    }

    // MARK: - Pro bypass

    func test_proUser_canAlwaysLog_evenAtFullQuota() {
        let logs = (0..<9).map { date(2026, 7, 1 + $0) }
        XCTAssertTrue(RateLimiter.canLogChange(existingLogs: logs, now: now, isPro: true, calendar: calendar))
    }

    func test_proUser_remainingCountStillComputedButIgnoredByCanLog() {
        // remainingLogsThisMonth has no isPro concept; canLogChange is what bypasses.
        let logs = (0..<5).map { date(2026, 7, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: calendar), 0)
        XCTAssertTrue(RateLimiter.canLogChange(existingLogs: logs, now: now, isPro: true, calendar: calendar))
    }

    // MARK: - Custom free limit

    func test_customFreeLimit_respected() {
        let logs = (0..<2).map { date(2026, 7, 1 + $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, freeLimit: 2, calendar: calendar), 0)
        XCTAssertFalse(RateLimiter.canLogChange(existingLogs: logs, now: now, freeLimit: 2, calendar: calendar))
    }
}
