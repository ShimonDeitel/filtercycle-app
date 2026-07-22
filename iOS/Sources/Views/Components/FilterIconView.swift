import SwiftUI

/// Animated "clogging" filter icon. As `elapsedFraction` (0 = new, 1 = due,
/// >1 = overdue) increases, the icon darkens and gains a coarse dot-texture
/// overlay to visually read as "clogged". Includes a "whoosh" clean animation
/// that plays when `justChanged` flips true (e.g. right after logging).
struct FilterIconView: View {
    let symbolName: String
    let elapsedFraction: Double
    let status: FilterStatus
    var justChanged: Bool = false

    @State private var whooshOffset: CGFloat = 0
    @State private var whooshOpacity: Double = 0

    private var clampedFraction: Double { min(max(elapsedFraction, 0), 1.3) }

    private var tintColor: Color {
        FCColor.statusColor(status)
    }

    private var clogOpacity: Double {
        // Texture ramps in starting around 40% elapsed, maxing near full clog.
        let t = max(0, (clampedFraction - 0.4) / 0.9)
        return min(0.55, t * 0.55)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(tintColor.opacity(0.12))
                .frame(width: 64, height: 64)

            Image(systemName: symbolName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(tintColor.opacity(1 - clogOpacity * 0.5))
                .saturation(1 - clogOpacity * 0.6)

            // Clog texture: a faint grid of dots darkening over the icon.
            ClogTexture(opacity: clogOpacity)
                .frame(width: 64, height: 64)
                .clipShape(Circle())

            if justChanged {
                Circle()
                    .stroke(FCColor.teal.opacity(whooshOpacity), lineWidth: 3)
                    .frame(width: 64, height: 64)
                    .scaleEffect(1 + whooshOffset)
            }
        }
        .onChange(of: justChanged) { _, newValue in
            guard newValue else { return }
            playWhoosh()
        }
    }

    private func playWhoosh() {
        whooshOffset = 0
        whooshOpacity = 0.9
        withAnimation(.easeOut(duration: 0.55)) {
            whooshOffset = 0.6
            whooshOpacity = 0
        }
    }
}

private struct ClogTexture: View {
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            guard opacity > 0.01 else { return }
            let spacing: CGFloat = 8
            var y: CGFloat = 4
            var row = 0
            while y < size.height {
                var x: CGFloat = row.isMultiple(of: 2) ? 4 : 8
                while x < size.width {
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(FCColor.slate.opacity(opacity)))
                    x += spacing
                }
                y += spacing
                row += 1
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    HStack(spacing: 20) {
        FilterIconView(symbolName: "wind", elapsedFraction: 0.1, status: .fresh)
        FilterIconView(symbolName: "wind", elapsedFraction: 0.85, status: .dueSoon)
        FilterIconView(symbolName: "wind", elapsedFraction: 1.4, status: .overdue)
    }
    .padding()
}
