import Foundation

/// A single logged "I changed this filter" event, counted against the free
/// monthly logging quota. Distinct from `Filter.lastChangedDate`, though the
/// app updates the latter whenever a log is recorded for a filter.
struct FilterChangeLog: Identifiable, Codable, Equatable {
    let id: UUID
    var filterID: UUID
    var date: Date

    init(id: UUID = UUID(), filterID: UUID, date: Date = Date()) {
        self.id = id
        self.filterID = filterID
        self.date = date
    }
}

/// Result of ranking filters to find the one that should be changed first.
struct FilterSuggestion: Equatable {
    let filter: Filter
    let daysRemaining: Int
    let status: FilterStatus
}

enum SuggestionEngine {
    /// Picks the single filter that should be changed first: the most overdue
    /// (or, if none are overdue, the one soonest due). Ties are broken
    /// alphabetically by filter name (case-insensitive).
    ///
    /// Ranking key is `daysRemaining` ascending — the most negative (most
    /// overdue) or smallest positive (soonest due) value wins. This naturally
    /// unifies both "most overdue" and "soonest due" into one ordering, since
    /// daysRemaining is a single continuous scale.
    static func suggestion(
        for filters: [Filter],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FilterSuggestion? {
        guard !filters.isEmpty else { return nil }

        let ranked = filters.map { filter -> FilterSuggestion in
            let remaining = filter.daysRemaining(now: now, calendar: calendar)
            let status = filter.status(now: now, calendar: calendar)
            return FilterSuggestion(filter: filter, daysRemaining: remaining, status: status)
        }

        return ranked.min { lhs, rhs in
            if lhs.daysRemaining != rhs.daysRemaining {
                return lhs.daysRemaining < rhs.daysRemaining
            }
            return lhs.filter.name.localizedCaseInsensitiveCompare(rhs.filter.name) == .orderedAscending
        }
    }
}
