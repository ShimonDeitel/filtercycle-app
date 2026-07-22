import Foundation

/// Pure, testable logic for the free-tier monthly logging cap. Free users get
/// `freeLimit` filter-change LOGS per rolling *calendar* month (reset is based
/// on the log timestamp's calendar month/year vs. `now`'s, not a rolling
/// 30-day window).
enum RateLimiter {
    /// Number of free logs remaining in the current calendar month.
    /// Never returns a negative number.
    static func remainingLogsThisMonth(
        existingLogs: [Date],
        now: Date = Date(),
        freeLimit: Int = 5,
        calendar: Calendar = .current
    ) -> Int {
        let usedThisMonth = logsInSameMonth(as: now, logs: existingLogs, calendar: calendar).count
        return max(0, freeLimit - usedThisMonth)
    }

    /// Whether a change can be logged right now: Pro users always can;
    /// free users can as long as remaining > 0.
    static func canLogChange(
        existingLogs: [Date],
        now: Date = Date(),
        isPro: Bool = false,
        freeLimit: Int = 5,
        calendar: Calendar = .current
    ) -> Bool {
        if isPro { return true }
        return remainingLogsThisMonth(existingLogs: existingLogs, now: now, freeLimit: freeLimit, calendar: calendar) > 0
    }

    /// Filters `logs` down to those falling in the same calendar year+month as `now`.
    static func logsInSameMonth(as now: Date, logs: [Date], calendar: Calendar = .current) -> [Date] {
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        return logs.filter { log in
            let logComponents = calendar.dateComponents([.year, .month], from: log)
            return logComponents.year == nowComponents.year && logComponents.month == nowComponents.month
        }
    }
}
