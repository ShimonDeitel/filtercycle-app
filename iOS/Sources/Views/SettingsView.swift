import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlements: EntitlementsStore
    @EnvironmentObject private var store: FilterStore
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(entitlements.isPro ? "Pro" : "Free")
                            .foregroundStyle(entitlements.isPro ? FCColor.teal : FCColor.slate)
                    }
                    if !entitlements.isPro {
                        HStack {
                            Text("Free logs left this month")
                            Spacer()
                            Text("\(store.remainingFreeLogs())")
                                .foregroundStyle(FCColor.slate)
                        }
                    }
                    Button {
                        isRestoring = true
                        Task {
                            await entitlements.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restore Purchases")
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(FCColor.slate)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/filtercycle/privacy.html")!)
                    Link("Terms of Use", destination: URL(string: "https://shimondeitel.github.io/filtercycle/terms.html")!)
                }

                // MARK: - Future: More Apps
                // Placeholder for a cross-promotion "More Apps" section, to be
                // added once the app-factory's shared cross-promo module is wired in.
            }
            .scrollContentBackground(.hidden)
            .background(FCColor.cream)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
