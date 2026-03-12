import SwiftUI

/// Overlay shown near the end of a video, displaying the next video's
/// thumbnail, title, and a countdown timer with play/cancel actions.
struct UpNextOverlayView: View {
    let nextVideo: Video
    let countdown: Int
    let totalCountdown: Int
    let onPlayNow: () -> Void
    let onCancel: () -> Void

    @FocusState private var focusedButton: UpNextButton?

    private enum UpNextButton {
        case playNow, cancel
    }

    var body: some View {
        HStack(spacing: 20) {
            // Thumbnail of next video
            FaceCenteredThumbnailView(url: nextVideo.thumbnailURL)
                .frame(width: 240, height: 135)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                // Header with countdown ring
                HStack(spacing: 10) {
                    CountdownRingView(
                        countdown: countdown,
                        total: totalCountdown
                    )

                    Text("Volgende video")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Next video title
                Text(nextVideo.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundStyle(.white)

                // Duration
                if nextVideo.duration > 0 {
                    Text(nextVideo.duration.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }

                // Buttons
                HStack(spacing: 12) {
                    Button(action: onPlayNow) {
                        Label("Afspelen", systemImage: "play.fill")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .focused($focusedButton, equals: .playNow)
                    .buttonStyle(UpNextButtonStyle(isPrimary: true))
                    .accessibilityLabel("Speel nu af: \(nextVideo.title)")

                    Button(action: onCancel) {
                        Text("Annuleren")
                            .font(.callout)
                    }
                    .focused($focusedButton, equals: .cancel)
                    .buttonStyle(UpNextButtonStyle(isPrimary: false))
                    .accessibilityLabel("Annuleer volgende video")
                }
            }
        }
        .padding(24)
        .background {
            if #available(tvOS 26, *) {
                RoundedRectangle(cornerRadius: 16)
                    .glassEffect()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.bottom, 80)
        .padding(.trailing, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .onAppear {
            focusedButton = .playNow
        }
    }

}

// MARK: - Countdown Ring

private struct CountdownRingView: View {
    let countdown: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(countdown) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: countdown)

            Text("\(countdown)")
                .font(.caption2)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(width: 32, height: 32)
        .accessibilityLabel("Aftelling: \(countdown) seconden")
    }
}

// MARK: - Button Style

private struct UpNextButtonStyle: ButtonStyle {
    let isPrimary: Bool
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background {
                if isPrimary {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.15))
                }
            }
            .foregroundStyle(isPrimary ? .black : .white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
