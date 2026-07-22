import Foundation

/// A single tracked household filter.
struct Filter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: FilterCategory
    /// Interval in days used for due-date math. Defaults to the category's
    /// typical interval, but is user-editable (required when category == .custom).
    var intervalDays: Int
    var lastChangedDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: FilterCategory,
        intervalDays: Int? = nil,
        lastChangedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.intervalDays = intervalDays ?? category.defaultIntervalDays
        self.lastChangedDate = lastChangedDate
    }

    /// Whole days elapsed since the filter was last changed, relative to `now`.
    /// Never negative (a future lastChangedDate clamps to 0).
    func daysSinceChanged(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: lastChangedDate)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(0, days)
    }

    /// Days remaining until due = intervalDays - daysSinceChanged. Can be negative.
    func daysRemaining(now: Date = Date(), calendar: Calendar = .current) -> Int {
        intervalDays - daysSinceChanged(now: now, calendar: calendar)
    }

    /// Current freshness status.
    func status(now: Date = Date(), calendar: Calendar = .current) -> FilterStatus {
        FilterStatus.status(
            daysRemaining: daysRemaining(now: now, calendar: calendar),
            intervalDays: intervalDays
        )
    }

    /// Fraction of the interval that has elapsed, clamped to [0, further-than-1 allowed
    /// for overdue rendering]. Used to drive the "clogging" visual — 0 = brand new,
    /// 1 = exactly due, >1 = overdue.
    func elapsedFraction(now: Date = Date(), calendar: Calendar = .current) -> Double {
        guard intervalDays > 0 else { return 1 }
        return Double(daysSinceChanged(now: now, calendar: calendar)) / Double(intervalDays)
    }
}
