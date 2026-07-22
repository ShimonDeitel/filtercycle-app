import SwiftUI

struct FilterDetailView: View {
    @EnvironmentObject private var store: FilterStore
    @Environment(\.dismiss) private var dismiss
    let filter: Filter

    @State private var justChanged = false

    private var currentFilter: Filter {
        store.filters.first(where: { $0.id == filter.id }) ?? filter
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FCColor.cream.ignoresSafeArea()

                VStack(spacing: 24) {
                    FilterIconView(
                        symbolName: currentFilter.category.symbolName,
                        elapsedFraction: currentFilter.elapsedFraction(),
                        status: currentFilter.status(),
                        justChanged: justChanged
                    )
                    .scaleEffect(1.8)
                    .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text(currentFilter.name)
                            .font(FCFont.title())
                            .foregroundStyle(FCColor.tealDeep)
                        Text(currentFilter.category.rawValue)
                            .font(FCFont.body())
                            .foregroundStyle(FCColor.slate)
                    }

                    VStack(spacing: 8) {
                        detailRow("Last changed", value: currentFilter.lastChangedDate.formatted(date: .abbreviated, time: .omitted))
                        detailRow("Days since changed", value: "\(currentFilter.daysSinceChanged())")
                        detailRow("Interval", value: "\(currentFilter.intervalDays) days")
                        detailRow("Status", value: currentFilter.status().rawValue, color: FCColor.statusColor(currentFilter.status()))
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Button {
                        logChange()
                    } label: {
                        Label("Mark as Changed", systemImage: "checkmark.circle.fill")
                            .font(FCFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FCColor.teal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $store.showPaywall) {
                PaywallView()
            }
        }
    }

    private func logChange() {
        let succeeded = store.logChange(for: currentFilter)
        if succeeded {
            justChanged = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                justChanged = false
            }
        }
    }

    private func detailRow(_ label: String, value: String, color: Color = FCColor.tealDeep) -> some View {
        HStack {
            Text(label)
                .font(FCFont.caption())
                .foregroundStyle(FCColor.slate)
            Spacer()
            Text(value)
                .font(FCFont.body().weight(.semibold))
                .foregroundStyle(color)
        }
    }
}
