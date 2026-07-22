import SwiftUI

struct FilterListView: View {
    @EnvironmentObject private var store: FilterStore
    @State private var selectedFilter: Filter?

    var body: some View {
        if store.filters.isEmpty {
            emptyState
        } else {
            List {
                ForEach(store.filters.sorted(by: { $0.daysRemaining() < $1.daysRemaining() })) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        FilterRow(filter: filter)
                    }
                    .listRowBackground(Color.white.opacity(0.001))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteFilter(filter)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .sheet(item: $selectedFilter) { filter in
                FilterDetailView(filter: filter)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wind")
                .font(.system(size: 44))
                .foregroundStyle(FCColor.teal.opacity(0.5))
            Text("No filters yet")
                .font(FCFont.headline())
                .foregroundStyle(FCColor.tealDeep)
            Text("Tap + to add your first HVAC, fridge, or vacuum filter.")
                .font(FCFont.caption())
                .foregroundStyle(FCColor.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FilterRow: View {
    let filter: Filter

    var body: some View {
        HStack(spacing: 14) {
            FilterIconView(
                symbolName: filter.category.symbolName,
                elapsedFraction: filter.elapsedFraction(),
                status: filter.status()
            )
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(filter.name)
                    .font(FCFont.body().weight(.semibold))
                    .foregroundStyle(FCColor.tealDeep)
                Text(filter.category.rawValue)
                    .font(FCFont.caption())
                    .foregroundStyle(FCColor.slate)
            }

            Spacer()

            StatusPill(status: filter.status(), daysRemaining: filter.daysRemaining())
        }
        .padding(.vertical, 6)
    }
}

private struct StatusPill: View {
    let status: FilterStatus
    let daysRemaining: Int

    var body: some View {
        Text(label)
            .font(FCFont.caption().weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(FCColor.statusColor(status))
            .clipShape(Capsule())
    }

    private var label: String {
        if daysRemaining < 0 {
            return "\(-daysRemaining)d overdue"
        } else if daysRemaining == 0 {
            return "Due today"
        } else {
            return "\(daysRemaining)d left"
        }
    }
}
