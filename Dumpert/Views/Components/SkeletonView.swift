import SwiftUI

/// Shimmer animation modifier for skeleton loading states.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.3

    func body(content: Content) -> some View {
        let leading = max(0, min(phase - 0.3, 1))
        let center = max(0, min(phase, 1))
        let trailing = max(0, min(phase + 0.3, 1))
        content
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: leading),
                        .init(color: .white.opacity(0.15), location: center),
                        .init(color: .clear, location: trailing)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipped()
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card

/// Matches the exact layout of VideoCardView: 16:9 thumbnail + title (2 lines) + kudos/date row.
private struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail — same as FaceCenteredThumbnailView (16:9, white.opacity(0.05) bg)
            Color.white.opacity(0.05)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipped()
                .shimmering()

            // Info — matches VideoCardView info section
            VStack(alignment: .leading, spacing: 4) {
                // Title: .caption, 2 lines with reservesSpace
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.08))
                    .frame(height: 12)
                    .shimmering()

                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.05))
                    .frame(width: .random(in: 60...120), height: 12)

                // Kudos + date row: .caption2
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.06))
                        .frame(width: 45, height: 9)

                    Circle()
                        .fill(.white.opacity(0.04))
                        .frame(width: 3, height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.06))
                        .frame(width: 55, height: 9)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Skeleton Grid

/// Matches CategorySectionView / ClassicsSectionView grid layout.
struct SkeletonGridView: View {
    let columnCount: Int

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: columnCount),
            spacing: 35
        ) {
            ForEach(0..<columnCount * 2, id: \.self) { _ in
                SkeletonCardView()
            }
        }
        .padding(.horizontal, 50)
    }
}

// MARK: - Skeleton Row

/// Matches ToppersSectionView mediaRow: title + horizontal scroll of cards.
struct SkeletonRowView: View {
    let cardWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section title placeholder — matches .title3.bold
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.08))
                .frame(width: 160, height: 18)
                .shimmering()

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonCardView()
                            .frame(width: cardWidth)
                    }
                }
                .padding(.vertical, 20)
            }
            .scrollClipDisabled()
        }
    }
}
