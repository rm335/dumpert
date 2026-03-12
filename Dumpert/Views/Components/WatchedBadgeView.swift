import SwiftUI

struct WatchedBadgeView: View {
    var body: some View {
        HStack {
            Image(systemName: "eye.fill")
                .font(.caption)
                .fontWeight(.bold)
            Text("Bekeken")
                .font(.caption2)
                .fontWeight(.bold)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .modifier(GlassBadgeModifier(cornerRadius: 6))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(10)
        .accessibilityLabel("Bekeken")
    }
}

/// Applies Liquid Glass on tvOS 26+, falls back to ultraThinMaterial on older versions.
private struct GlassBadgeModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(tvOS 26, *) {
            content
                .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial)
                .cornerRadius(cornerRadius)
        }
    }
}
