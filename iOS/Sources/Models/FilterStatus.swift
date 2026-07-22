import Foundation

/// Freshness status of a filter, derived from the fraction of its interval remaining.
enum FilterStatus: String, Codable {
    case fresh = "Fresh"
    case dueSoon = "Due Soon"
    case overdue = "Overdue"

    /// Threshold, as a fraction of the interval, below which a filter is "Due Soon"
    /// rather than "Fresh". At exactly 25% remaining a filter is still "Due Soon"
    /// (the boundary belongs to the more urgent bucket); above 25% is "Fresh".
    static let dueSoonThresholdFraction: Double = 0.25

    /// Compute status from days-remaining and the category's interval.
    /// - Parameters:
    ///   - daysRemaining: interval - daysSinceChanged. May be negative (overdue).
    ///   - intervalDays: the category's total interval, in days. Must be > 0.
    static func status(daysRemaining: Int, intervalDays: Int) -> FilterStatus {
        guard intervalDays > 0 else { return .overdue }
        if daysRemaining < 0 {
            return .overdue
        }
        let remainingFraction = Double(daysRemaining) / Double(intervalDays)
        if remainingFraction <= dueSoonThresholdFraction {
            return .dueSoon
        }
        return .fresh
    }
}
