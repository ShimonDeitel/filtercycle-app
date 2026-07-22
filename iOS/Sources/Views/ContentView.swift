import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: FilterStore
    @State private var showAddFilter = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                FCColor.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    if store.shouldShowSoftNudge() {
                        SoftNudgeBanner {
                            store.hasShownSoftNudgeThisSession = true
                            store.showPaywall = true
                        } onDismiss: {
                            store.hasShownSoftNudgeThisSession = true
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    if let suggestion = store.topSuggestion() {
                        SuggestionBannerView(suggestion: suggestion)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    FilterListView()
                }
            }
            .navigationTitle("Filtercycle")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(FCColor.tealDeep)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFilter = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .tint(FCColor.teal)
                }
            }
            .sheet(isPresented: $showAddFilter) {
                AddFilterView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $store.showPaywall) {
                PaywallView()
            }
        }
    }
}

private struct SoftNudgeBanner: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(FCColor.amber)
            Text("1 free log left this month —")
                .font(FCFont.caption())
                .foregroundStyle(FCColor.slate)
            Button("upgrade for unlimited", action: onUpgrade)
                .font(FCFont.caption().bold())
                .foregroundStyle(FCColor.tealDeep)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(FCColor.slate)
            }
        }
        .padding(10)
        .background(FCColor.slateLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
        .environmentObject(FilterStore(entitlements: EntitlementsStore(), nudgeScheduler: UpgradeNudgeScheduler(scheduler: SystemNotificationScheduler())))
        .environmentObject(EntitlementsStore())
}
