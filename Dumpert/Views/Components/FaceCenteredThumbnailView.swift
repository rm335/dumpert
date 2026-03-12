import SwiftUI

/// Loads a remote image, detects faces with Vision, and displays it
/// centering on the most prominent face so it doesn't get cut off.
///
/// By default wraps in a 16:9 container. Set `useIntrinsicAspectRatio` to false
/// when the parent already constrains the size (e.g. hero banner with fixed height).
struct FaceCenteredThumbnailView: View {
    let url: URL?
    var useIntrinsicAspectRatio: Bool = true

    @State private var image: UIImage?
    @State private var faceCenter: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var phase: Phase = .loading

    private enum Phase {
        case loading, success, failure
    }

    var body: some View {
        container
            .clipped()
            .task(id: url) {
                await loadAndDetect()
            }
    }

    @ViewBuilder
    private var container: some View {
        if useIntrinsicAspectRatio {
            Color.clear
                .aspectRatio(16/9, contentMode: .fit)
                .overlay { content }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        GeometryReader { geo in
            switch phase {
            case .success:
                if let image {
                    faceCenteredImage(image: image, in: geo.size)
                }
            case .loading:
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .overlay { ProgressView() }
            case .failure:
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
            }
        }
    }

    @ViewBuilder
    private func faceCenteredImage(image: UIImage, in containerSize: CGSize) -> some View {
        let imgSize = image.size
        let scale = max(
            containerSize.width / imgSize.width,
            containerSize.height / imgSize.height
        )
        let scaledW = imgSize.width * scale
        let scaledH = imgSize.height * scale

        let offsetX = Self.clampedOffset(
            faceNormalized: faceCenter.x,
            scaledDim: scaledW,
            containerDim: containerSize.width
        )
        let offsetY = Self.clampedOffset(
            faceNormalized: faceCenter.y,
            scaledDim: scaledH,
            containerDim: containerSize.height
        )

        Image(uiImage: image)
            .resizable()
            .frame(width: scaledW, height: scaledH)
            .offset(x: offsetX, y: offsetY)
    }

    /// Compute offset to center face in container, clamped so no gaps appear.
    private static func clampedOffset(
        faceNormalized: CGFloat,
        scaledDim: CGFloat,
        containerDim: CGFloat
    ) -> CGFloat {
        let facePos = faceNormalized * scaledDim
        let idealOffset = containerDim / 2 - facePos
        let minOffset = containerDim - scaledDim
        return min(0, max(minOffset, idealOffset))
    }

    private func loadAndDetect() async {
        guard let url else {
            phase = .failure
            return
        }

        phase = .loading

        do {
            let uiImage = try await ImageCacheService.shared.image(for: url)

            var center = CGPoint(x: 0.5, y: 0.5)
            if let cgImage = uiImage.cgImage {
                center = await FaceDetectionService.shared.faceCenter(
                    for: url,
                    in: cgImage
                )
            }

            self.image = uiImage
            self.faceCenter = center
            self.phase = .success
        } catch {
            phase = .failure
        }
    }
}
