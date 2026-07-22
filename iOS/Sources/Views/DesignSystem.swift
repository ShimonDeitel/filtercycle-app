import SwiftUI

/// Bespoke Filtercycle palette: cool soft teal + slate gray, warm coral
/// reserved strictly for "overdue" signaling. Deliberately not the generic
/// black/white/blue look used elsewhere.
enum FCColor {
    static let teal = Color(red: 0.20, green: 0.53, blue: 0.52)      // soft teal, primary
    static let tealDeep = Color(red: 0.11, green: 0.34, blue: 0.36)   // deep teal, headers
    static let slate = Color(red: 0.35, green: 0.40, blue: 0.44)      // slate gray, secondary text
    static let slateLight = Color(red: 0.86, green: 0.89, blue: 0.90) // pale slate, surfaces
    static let coral = Color(red: 0.92, green: 0.42, blue: 0.36)      // warm coral, overdue only
    static let amber = Color(red: 0.90, green: 0.66, blue: 0.30)      // due-soon accent
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.94)      // background

    static func statusColor(_ status: FilterStatus) -> Color {
        switch status {
        case .fresh: return teal
        case .dueSoon: return amber
        case .overdue: return coral
        }
    }
}

enum FCFont {
    static func title() -> Font { .system(.title2, design: .rounded).weight(.bold) }
    static func headline() -> Font { .system(.headline, design: .rounded) }
    static func body() -> Font { .system(.body, design: .rounded) }
    static func caption() -> Font { .system(.caption, design: .rounded) }
}

/// Tap-anywhere keyboard dismiss, applied at the root of forms/screens with
/// text fields. Uses a real drag gesture over the whole background rather
/// than relying on scroll-to-dismiss, so it also works on short forms.
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
