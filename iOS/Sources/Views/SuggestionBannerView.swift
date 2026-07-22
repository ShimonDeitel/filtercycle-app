import SwiftUI

/// "Change this filter first" callout for the single most urgent filter
/// across the whole collection.
struct SuggestionBannerView: View {
    let suggestion: FilterSuggestion

    var body: some View {
        HStack(spacing: 12) {
            FilterIconView(
                symbolName: suggestion.filter.category.symbolName,
                elapsedFraction: suggestion.filter.elapsedFraction(),
                status: suggestion.status
            )
            .scaleEffect(0.7)
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Change this filter first")
                    .font(FCFont.caption())
                    .foregroundStyle(FCColor.slate)
                Text(suggestion.filter.name)
                    .font(FCFont.headline())
                    .foregroundStyle(FCColor.tealDeep)
                Text(statusText)
                    .font(FCFont.caption())
                    .foregroundStyle(FCColor.statusColor(suggestion.status))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FCColor.statusColor(suggestion.status).opacity(0.4), lineWidth: 1)
        )
    }

    private var statusText: String {
        if suggestion.daysRemaining < 0 {
            return "\(-suggestion.daysRemaining) day\(suggestion.daysRemaining == -1 ? "" : "s") overdue"
        } else if suggestion.daysRemaining == 0 {
            return "Due today"
        } else {
            return "Due in \(suggestion.daysRemaining) day\(suggestion.daysRemaining == 1 ? "" : "s")"
        }
    }
}
