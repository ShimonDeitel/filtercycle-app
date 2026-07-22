import SwiftUI

/// Hard-block modal shown when a free user tries to log a change beyond
/// their 5 free logs this month.
struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FCColor.cream.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "wind")
                        .font(.system(size: 46))
                        .foregroundStyle(FCColor.coral)
                        .padding(.top, 12)

                    Text("You've used all 5 free logs this month")
                        .font(FCFont.title())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(FCColor.tealDeep)

                    Text("Filtercycle Pro unlocks unlimited filter-change logging, every month, for every filter in your home.")
                        .font(FCFont.body())
                        .foregroundStyle(FCColor.slate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        featureRow("Unlimited monthly logs")
                        featureRow("Unlimited filters")
                        featureRow("Priority change suggestions")
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        Task {
                            await entitlements.purchasePro()
                            if entitlements.isPro { dismiss() }
                        }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(FCFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FCColor.teal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(FCFont.body())
                    .foregroundStyle(FCColor.slate)
                    .padding(.bottom, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func featureRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(FCFont.body())
            .foregroundStyle(FCColor.tealDeep)
    }
}
