import SwiftUI

struct FullScreenImageView: View {
    let photo: Photo
    let repository: VideoRepository
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false

    // Zoom & pan state (controlled via Siri Remote)
    @State var currentScale: CGFloat = 1.0
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State var showOverlay = true

    @FocusState private var isFocused: Bool

    let zoomStep: CGFloat = 0.5
    private let panStep: CGFloat = 100
    let minScale: CGFloat = 1.0
    let maxScale: CGFloat = 5.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView("Laden...")
            } else if loadFailed {
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Kon afbeelding niet laden")
                        .foregroundStyle(.secondary)
                }
            } else if let image {
                imageContent(image)
            }

            // Overlay with title and info
            if showOverlay {
                overlay
            }

            // Zoom controls overlay (bottom right)
            if !isLoading && !loadFailed && image != nil {
                zoomControls
            }
        }
        .task {
            await loadImage()
            markAsWatched()
        }
        .onExitCommand {
            if currentScale > minScale {
                withAnimation(.spring(duration: 0.3)) {
                    resetZoom()
                }
            } else {
                dismiss()
            }
        }
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.2)) {
                showOverlay.toggle()
            }
        }
    }

    @ViewBuilder
    private func imageContent(_ uiImage: UIImage) -> some View {
        let base = Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(currentScale)
            .offset(x: offsetX, y: offsetY)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(photo.title)
            .focusable()
            .focused($isFocused)
            .onAppear { isFocused = true }

        // Only intercept move commands when zoomed in;
        // at 1x the focus engine can navigate to the zoom buttons
        if currentScale > minScale {
            base.onMoveCommand { direction in
                withAnimation(.easeOut(duration: 0.2)) {
                    switch direction {
                    case .left: offsetX += panStep
                    case .right: offsetX -= panStep
                    case .up: offsetY += panStep
                    case .down: offsetY -= panStep
                    @unknown default: break
                    }
                }
            }
        } else {
            base
        }
    }

    // MARK: - Helpers

    private func loadImage() async {
        guard let url = photo.imageURL ?? photo.thumbnailURL else {
            isLoading = false
            loadFailed = true
            return
        }

        do {
            let uiImage = try await ImageCacheService.shared.image(for: url)
            self.image = uiImage
            isLoading = false
        } catch {
            isLoading = false
            loadFailed = true
        }
    }

    private func markAsWatched() {
        repository.updateWatchProgress(
            videoId: photo.id,
            watchedSeconds: 1,
            totalSeconds: 1
        )
    }

    func resetZoom() {
        currentScale = minScale
        offsetX = 0
        offsetY = 0
    }
}
