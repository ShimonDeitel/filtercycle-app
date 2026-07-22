import XCTest
@testable import Filtercycle

final class SuggestionTests: XCTestCase {
    private var cal: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))!
    }

    private func filter(name: String, intervalDays: Int, daysAgo: Int) -> Filter {
        let lastChanged = cal.date(byAdding: .day, value: -daysAgo, to: now)!
        return Filter(name: name, category: .custom, intervalDays: intervalDays, lastChangedDate: lastChanged)
    }

    func test_emptyList_returnsNil() {
        XCTAssertNil(SuggestionEngine.suggestion(for: [], now: now, calendar: cal))
    }

    func test_singleFilter_isTheSuggestion() {
        let f = filter(name: "Solo", intervalDays: 90, daysAgo: 10)
        let suggestion = SuggestionEngine.suggestion(for: [f], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.filter.id, f.id)
    }

    func test_mostOverdueFilter_isPickedOverLessOverdue() {
        let mild = filter(name: "Mild", intervalDays: 90, daysAgo: 95)   // -5 remaining
        let severe = filter(name: "Severe", intervalDays: 90, daysAgo: 150) // -60 remaining
        let fresh = filter(name: "Fresh", intervalDays: 90, daysAgo: 5)  // 85 remaining
        let suggestion = SuggestionEngine.suggestion(for: [mild, severe, fresh], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.filter.name, "Severe")
        XCTAssertEqual(suggestion?.daysRemaining, -60)
    }

    func test_noneOverdue_soonestDueIsPicked() {
        let soon = filter(name: "Soon", intervalDays: 90, daysAgo: 85)     // 5 remaining
        let later = filter(name: "Later", intervalDays: 90, daysAgo: 30)   // 60 remaining
        let suggestion = SuggestionEngine.suggestion(for: [soon, later], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.filter.name, "Soon")
        XCTAssertEqual(suggestion?.daysRemaining, 5)
    }

    func test_tie_brokenAlphabeticallyByName() {
        let bravo = filter(name: "Bravo", intervalDays: 90, daysAgo: 95) // -5 remaining
        let alpha = filter(name: "Alpha", intervalDays: 90, daysAgo: 95) // -5 remaining, same
        let charlie = filter(name: "Charlie", intervalDays: 90, daysAgo: 95) // -5 remaining, same
        let suggestion = SuggestionEngine.suggestion(for: [bravo, alpha, charlie], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.filter.name, "Alpha")
    }

    func test_tie_alphabeticalIsCaseInsensitive() {
        let upper = filter(name: "ZEBRA", intervalDays: 90, daysAgo: 95)
        let lower = filter(name: "apple", intervalDays: 90, daysAgo: 95)
        let suggestion = SuggestionEngine.suggestion(for: [upper, lower], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.filter.name, "apple")
    }

    func test_tie_breakingDoesNotDependOnInputOrder() {
        let a = filter(name: "Aaa", intervalDays: 90, daysAgo: 95)
        let b = filter(name: "Bbb", intervalDays: 90, daysAgo: 95)
        let firstOrder = SuggestionEngine.suggestion(for: [a, b], now: now, calendar: cal)
        let secondOrder = SuggestionEngine.suggestion(for: [b, a], now: now, calendar: cal)
        XCTAssertEqual(firstOrder?.filter.name, "Aaa")
        XCTAssertEqual(secondOrder?.filter.name, "Aaa")
    }

    func test_mixOfOverdueAndDueSoon_overdueAlwaysWinsRegardlessOfMagnitudeOfDueSoon() {
        // A filter that's barely overdue beats one that's "due very soon" but not yet overdue.
        let barelyOverdue = filter(name: "BarelyOverdue", intervalDays: 90, daysAgo: 91) // -1 remaining
        let dueSoon = filter(name: "DueSoon", intervalDays: 90, daysAgo: 89) // 1 remaining
        let suggestion = SuggestionEngine.suggestion(for: [barelyOverdue, dueSoon], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.filter.name, "BarelyOverdue")
        XCTAssertEqual(suggestion?.status, .overdue)
    }

    func test_suggestionStatus_matchesFilterStatus() {
        let f = filter(name: "Check", intervalDays: 90, daysAgo: 95)
        let suggestion = SuggestionEngine.suggestion(for: [f], now: now, calendar: cal)
        XCTAssertEqual(suggestion?.status, f.status(now: now, calendar: cal))
    }
}
