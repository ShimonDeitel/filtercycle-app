import SwiftUI

@main
struct FiltercycleApp: App {
    @StateObject private var entitlements = EntitlementsStore()
    @StateObject private var store: FilterStore

    init() {
        let ent = EntitlementsStore()
        _entitlements = StateObject(wrappedValue: ent)
        let scheduler = UpgradeNudgeScheduler(scheduler: SystemNotificationScheduler())
        _store = StateObject(wrappedValue: FilterStore(entitlements: ent, nudgeScheduler: scheduler))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(entitlements)
        }
    }
}
