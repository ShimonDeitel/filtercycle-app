import Foundation
import Combine

/// App-wide observable state: filters, change logs, and the derived
/// rate-limit / suggestion / paywall UI signals. Persists to UserDefaults
/// via JSON for simplicity (no CloudKit requirement in this app).
@MainActor
final class FilterStore: ObservableObject {
    @Published private(set) var filters: [Filter] = []
    @Published private(set) var changeLogs: [FilterChangeLog] = []

    /// Set true exactly once per app session after the first "1 remaining"
    /// soft-nudge banner has been shown, so it doesn't reappear on every screen.
    @Published var hasShownSoftNudgeThisSession = false
    @Published var showPaywall = false

    private let defaults: UserDefaults
    private let filtersKey = "filtercycle.filters"
    private let logsKey = "filtercycle.changeLogs"

    let entitlements: EntitlementsStore
    let nudgeScheduler: UpgradeNudgeScheduler

    init(
        defaults: UserDefaults = .standard,
        entitlements: EntitlementsStore,
        nudgeScheduler: UpgradeNudgeScheduler
    ) {
        self.defaults = defaults
        self.entitlements = entitlements
        self.nudgeScheduler = nudgeScheduler
        load()
    }

    // MARK: - Filters

    func addFilter(name: String, category: FilterCategory, intervalDays: Int?, lastChangedDate: Date) {
        let filter = Filter(
            name: name,
            category: category,
            intervalDays: intervalDays,
            lastChangedDate: lastChangedDate
        )
        filters.append(filter)
        persist()
    }

    func deleteFilter(_ filter: Filter) {
        filters.removeAll { $0.id == filter.id }
        changeLogs.removeAll { $0.filterID == filter.id }
        persist()
    }

    func updateFilter(_ filter: Filter) {
        guard let idx = filters.firstIndex(where: { $0.id == filter.id }) else { return }
        filters[idx] = filter
        persist()
    }

    // MARK: - Logging a change (rate-limited)

    /// Attempts to log a filter change "now". Returns true if it succeeded;
    /// false if the free monthly cap was hit (in which case `showPaywall` is
    /// set and the nudge scheduler is engaged).
    @discardableResult
    func logChange(for filter: Filter, now: Date = Date()) -> Bool {
        let existing = changeLogs.map(\.date)
        guard RateLimiter.canLogChange(existingLogs: existing, now: now, isPro: entitlements.isPro) else {
            showPaywall = true
            nudgeScheduler.handleLimitHit(at: now)
            return false
        }

        changeLogs.append(FilterChangeLog(filterID: filter.id, date: now))
        if let idx = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[idx].lastChangedDate = now
        }
        persist()
        return true
    }

    /// Remaining free logs this month, for banner/badge display.
    func remainingFreeLogs(now: Date = Date()) -> Int {
        RateLimiter.remainingLogsThisMonth(existingLogs: changeLogs.map(\.date), now: now)
    }

    /// Whether the "1 remaining" soft-nudge banner should be shown right now.
    func shouldShowSoftNudge(now: Date = Date()) -> Bool {
        guard !entitlements.isPro, !hasShownSoftNudgeThisSession else { return false }
        return remainingFreeLogs(now: now) == 1
    }

    // MARK: - Suggestion

    func topSuggestion(now: Date = Date()) -> FilterSuggestion? {
        SuggestionEngine.suggestion(for: filters, now: now)
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(filters) {
            defaults.set(data, forKey: filtersKey)
        }
        if let data = try? JSONEncoder().encode(changeLogs) {
            defaults.set(data, forKey: logsKey)
        }
    }

    private func load() {
        if let data = defaults.data(forKey: filtersKey),
           let decoded = try? JSONDecoder().decode([Filter].self, from: data) {
            filters = decoded
        }
        if let data = defaults.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([FilterChangeLog].self, from: data) {
            changeLogs = decoded
        }
    }
}
