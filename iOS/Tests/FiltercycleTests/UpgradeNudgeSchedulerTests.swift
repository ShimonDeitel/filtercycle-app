import XCTest
@testable import Filtercycle

/// Records calls instead of touching real UNUserNotificationCenter, so
/// scheduling logic is testable without permission prompts.
final class MockNotificationScheduler: NotificationScheduling {
    var authorizationGranted = true
    var requestAuthorizationCallCount = 0
    var scheduledCalls: [(id: String, title: String, body: String, fireDate: Date)] = []
    var cancelledIDs: [String] = []

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        requestAuthorizationCallCount += 1
        completion(authorizationGranted)
    }

    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) {
        scheduledCalls.append((id, title, body, fireDate))
    }

    func cancelNotification(id: String) {
        cancelledIDs.append(id)
    }
}

final class UpgradeNudgeSchedulerTests: XCTestCase {
    private var cal: Calendar!

    override func setUp() {
        super.setUp()
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    // MARK: - Fire date computed ~20 hours out

    func test_fireDate_isTwentyHoursAfterHitLimitDate() {
        let hit = date(2026, 7, 15, 10)
        let fire = UpgradeNudgeScheduler.fireDate(from: hit)
        XCTAssertEqual(fire.timeIntervalSince(hit), 20 * 3600, accuracy: 0.001)
    }

    // MARK: - First hit: requests permission and schedules

    func test_firstLimitHit_requestsAuthorizationAndSchedulesOneNotification() {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: cal)
        let hit = date(2026, 7, 15)

        let expectation = expectation(description: "completion called")
        scheduler.handleLimitHit(at: hit) { scheduled in
            XCTAssertTrue(scheduled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mock.requestAuthorizationCallCount, 1)
        XCTAssertEqual(mock.scheduledCalls.count, 1)
        XCTAssertEqual(mock.scheduledCalls.first?.body, UpgradeNudgeScheduler.notificationBody)
        let fireDate = try! XCTUnwrap(mock.scheduledCalls.first?.fireDate)
        XCTAssertEqual(
            fireDate.timeIntervalSince(hit),
            20 * 3600,
            accuracy: 0.001
        )
    }

    // MARK: - Dedup: second hit same month does not re-schedule or re-prompt

    func test_secondLimitHitSameMonth_doesNotRequestAuthorizationAgain() {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: cal)

        let firstHit = date(2026, 7, 15)
        let secondHit = date(2026, 7, 28)

        let exp1 = expectation(description: "first")
        scheduler.handleLimitHit(at: firstHit) { _ in exp1.fulfill() }
        wait(for: [exp1], timeout: 1)

        let exp2 = expectation(description: "second")
        scheduler.handleLimitHit(at: secondHit) { scheduled in
            XCTAssertFalse(scheduled)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1)

        XCTAssertEqual(mock.requestAuthorizationCallCount, 1, "should not re-prompt within same month")
        XCTAssertEqual(mock.scheduledCalls.count, 1, "should not schedule a second notification within same month")
    }

    // MARK: - New month: nudge can fire again

    func test_limitHitInNewMonth_schedulesAgain() {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: cal)

        let julyHit = date(2026, 7, 15)
        let augustHit = date(2026, 8, 3)

        let exp1 = expectation(description: "july")
        scheduler.handleLimitHit(at: julyHit) { _ in exp1.fulfill() }
        wait(for: [exp1], timeout: 1)

        let exp2 = expectation(description: "august")
        scheduler.handleLimitHit(at: augustHit) { scheduled in
            XCTAssertTrue(scheduled)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1)

        XCTAssertEqual(mock.requestAuthorizationCallCount, 2)
        XCTAssertEqual(mock.scheduledCalls.count, 2)
        XCTAssertNotEqual(mock.scheduledCalls[0].id, mock.scheduledCalls[1].id)
    }

    // MARK: - Permission denied: no schedule, but attempt is still tracked as "not scheduled"

    func test_permissionDenied_doesNotSchedule() {
        let mock = MockNotificationScheduler()
        mock.authorizationGranted = false
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: cal)

        let hit = date(2026, 7, 15)
        let exp = expectation(description: "denied")
        scheduler.handleLimitHit(at: hit) { scheduled in
            XCTAssertFalse(scheduled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(mock.scheduledCalls.count, 0)
    }

    func test_permissionDeniedThenGrantedLaterSameMonth_canStillScheduleOnRetry() {
        // Since a denied attempt never marks the month as "scheduled", a later
        // retry within the same month (e.g. user changes Settings mid-session)
        // should still be able to schedule.
        let mock = MockNotificationScheduler()
        mock.authorizationGranted = false
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: cal)

        let hit = date(2026, 7, 15)
        let exp1 = expectation(description: "denied")
        scheduler.handleLimitHit(at: hit) { _ in exp1.fulfill() }
        wait(for: [exp1], timeout: 1)

        mock.authorizationGranted = true
        let exp2 = expectation(description: "granted retry")
        scheduler.handleLimitHit(at: hit) { scheduled in
            XCTAssertTrue(scheduled)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1)

        XCTAssertEqual(mock.scheduledCalls.count, 1)
    }

    // MARK: - monthKey / notificationID formatting

    func test_monthKey_formatsWithZeroPaddedMonth() {
        XCTAssertEqual(UpgradeNudgeScheduler.monthKey(for: date(2026, 1, 5), calendar: cal), "2026-01")
        XCTAssertEqual(UpgradeNudgeScheduler.monthKey(for: date(2026, 12, 5), calendar: cal), "2026-12")
    }

    func test_hasScheduledNudge_reflectsPriorScheduling() {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: cal)
        let hit = date(2026, 7, 15)

        XCTAssertFalse(scheduler.hasScheduledNudge(for: hit))
        let exp = expectation(description: "scheduled")
        scheduler.handleLimitHit(at: hit) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(scheduler.hasScheduledNudge(for: hit))
    }

    func test_preExistingScheduledMonthKeys_preventsPromptOnInit() {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(
            scheduler: mock,
            alreadyScheduledMonthKeys: ["2026-07"],
            calendar: cal
        )
        let hit = date(2026, 7, 20)
        let exp = expectation(description: "no-op")
        scheduler.handleLimitHit(at: hit) { scheduled in
            XCTAssertFalse(scheduled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(mock.requestAuthorizationCallCount, 0)
    }
}
