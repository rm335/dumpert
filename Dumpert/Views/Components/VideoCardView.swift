import SwiftUI

struct VideoCardView: View {
    let item: MediaItem
    let isWatched: Bool
    let progress: Double
    var isFocused: Bool = false
    var thumbnailPreviewEnabled: Bool = true

    @State private var showPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack {
                FaceCenteredThumbnailView(url: item.thumbnailURL)
                    .brightness(isFocused ? 0.05 : 0)
                    .saturation(isFocused ? 1.15 : 1.0)
                    .accessibilityHidden(true)

                // Video preview overlay (max 10% of duration, minimum 10s)
                if showPreview, let streamURL = item.streamURL {
                    VideoPreviewView(
                        url: streamURL,
                        maxDuration: previewMaxDuration
                    )
                    .transition(.opacity)
                }

                // Mute indicator when preview is playing
                if showPreview {
                    Image(systemName: "speaker.slash.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .modifier(GlassPillModifier())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(6)
                        .transition(.opacity)
                }

                // Watched badge - top trailing
                if isWatched {
                    WatchedBadgeView()
                }

                // Duration pill or photo icon - bottom trailing (hidden during preview)
                if !showPreview {
                    if case .video(let video) = item, video.duration > 0 {
                        Text(video.duration.formattedDuration)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .modifier(GlassPillModifier())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(6)
                    } else if item.isPhoto {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .modifier(GlassPillModifier())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(6)
                    }
                }

                // Progress bar at bottom (only for videos)
                if item.isVideo && progress > 0 && !isWatched {
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.white.opacity(0.15))
                                    .frame(height: 5)
                                Rectangle()
                                    .fill(Color.dumpiGreen)
                                    .frame(width: geo.size.width * progress, height: 5)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: .dumpiGreen.opacity(isFocused ? 0.3 : 0), radius: 15)
            .animation(.spring(duration: 0.35), value: isFocused)

            // Info below thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isWatched ? .secondary : .primary)

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: item.kudosTotal >= 0 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                            .font(.system(size: 9))
                        Text(formattedKudos)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .foregroundStyle(kudosColor)

                    if let date = item.date {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(date.relativeString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .task(id: isFocused) {
            if isFocused && item.isVideo && item.streamURL != nil && thumbnailPreviewEnabled {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.3)) {
                    showPreview = true
                }
            } else if showPreview {
                withAnimation(.easeOut(duration: 0.2)) {
                    showPreview = false
                }
            }
        }
    }

    /// Preview shows at most 10% of the video, but never less than 10 seconds.
    private var previewMaxDuration: TimeInterval? {
        let duration = item.duration
        guard duration > 0 else { return nil }
        return max(10, Double(duration) * 0.10)
    }

    private var formattedKudos: String {
        let k = item.kudosTotal
        if abs(k) >= 1000 {
            return String(format: "%.1fk", Double(k) / 1000)
        }
        return "\(k)"
    }

    private var accessibilityDescription: String {
        var parts: [String] = [item.title]
        if item.isVideo {
            parts.append(String(localized: "Video", comment: "Accessibility: content type video"))
            if item.duration > 0 {
                parts.append(item.duration.formattedDuration)
            }
        } else {
            parts.append(String(localized: "Foto", comment: "Accessibility: content type photo"))
        }
        parts.append("\(formattedKudos) kudos")
        if isWatched {
            parts.append(String(localized: "Bekeken", comment: "Accessibility: video has been watched"))
        } else if progress > 0 {
            parts.append(String(localized: "\(Int(progress * 100))% bekeken", comment: "Accessibility: percentage of video watched"))
        }
        return parts.joined(separator: ", ")
    }

    private var kudosColor: Color {
        if item.kudosTotal >= 100 { return .green }
        if item.kudosTotal >= 0 { return .gray }
        return .red
    }

}

/// Applies Liquid Glass on tvOS 26+, falls back to dark pill on older versions.
private struct GlassPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(tvOS 26, *) {
            content
                .glassEffect(in: RoundedRectangle(cornerRadius: 4))
        } else {
            content
                .background(.black.opacity(0.75))
                .cornerRadius(4)
        }
    }
}
