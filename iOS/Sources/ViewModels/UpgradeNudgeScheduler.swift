import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Thin seam over UNUserNotificationCenter so scheduling *logic* (computed
/// fire date, per-month dedup) is unit-testable without touching real
/// notification permissions.
protocol NotificationScheduling {
    /// Requests permission; completion receives whether it was granted.
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    /// Schedules a local notification with the given identifier to fire at `date`.
    func scheduleNotification(id: String, title: String, body: String, fireDate: Date)
    /// Cancels a previously scheduled notification, if any.
    func cancelNotification(id: String)
}

#if canImport(UserNotifications)
/// Real UNUserNotificationCenter-backed implementation.
final class SystemNotificationScheduler: NotificationScheduling {
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(1, fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
#endif

/// Schedules (at most once per calendar month) a single local notification
/// ~20 hours after a free user first hits their monthly logging limit.
final class UpgradeNudgeScheduler {
    static let hoursDelay: Double = 20
    static let notificationTitle = "Filtercycle"
    static let notificationBody = "Still tracking filter changes this month? Upgrade to Filtercycle Pro for unlimited logging."

    private let scheduler: NotificationScheduling
    /// Tracks the year-month key ("yyyy-MM") for which a nudge has already
    /// been scheduled, so we never double-schedule within the same month.
    private var scheduledMonthKeys: Set<String>
    private let calendar: Calendar

    init(
        scheduler: NotificationScheduling,
        alreadyScheduledMonthKeys: Set<String> = [],
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.scheduledMonthKeys = alreadyScheduledMonthKeys
        self.calendar = calendar
    }

    /// Identifier used for the scheduled notification for a given month key.
    static func notificationID(monthKey: String) -> String {
        "upgrade-nudge-\(monthKey)"
    }

    /// "yyyy-MM" key for the calendar month containing `date`.
    static func monthKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
    }

    /// The fire date for a nudge triggered at `hitLimitDate`.
    static func fireDate(from hitLimitDate: Date) -> Date {
        hitLimitDate.addingTimeInterval(hoursDelay * 3600)
    }

    /// Whether a nudge has already been scheduled for the calendar month
    /// containing `date`.
    func hasScheduledNudge(for date: Date) -> Bool {
        scheduledMonthKeys.contains(Self.monthKey(for: date, calendar: calendar))
    }

    /// Call the first time a free user hits their monthly cap. Requests
    /// notification permission contextually, and if granted (and no nudge is
    /// already scheduled for this calendar month) schedules exactly one
    /// local notification ~20 hours out. No-ops (does not re-prompt or
    /// re-schedule) if a nudge already exists for this month.
    func handleLimitHit(at date: Date = Date(), completion: ((Bool) -> Void)? = nil) {
        guard !hasScheduledNudge(for: date) else {
            completion?(false)
            return
        }

        scheduler.requestAuthorization { [weak self] granted in
            guard let self else { completion?(false); return }
            guard granted else { completion?(false); return }

            let key = Self.monthKey(for: date, calendar: self.calendar)
            self.scheduledMonthKeys.insert(key)
            self.scheduler.scheduleNotification(
                id: Self.notificationID(monthKey: key),
                title: Self.notificationTitle,
                body: Self.notificationBody,
                fireDate: Self.fireDate(from: date)
            )
            completion?(true)
        }
    }
}
