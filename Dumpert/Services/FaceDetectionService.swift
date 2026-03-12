import Vision

actor FaceDetectionService {
    static let shared = FaceDetectionService()

    // Cache: URL → normalized face center (UIKit coords, top-left origin)
    private var cache: [URL: CGPoint] = [:]

    /// Returns the center of the most prominent face in the image, or (0.5, 0.5) if none found.
    /// Result is in normalized UIKit coordinates (0,0 = top-left, 1,1 = bottom-right).
    func faceCenter(for url: URL, in cgImage: CGImage) -> CGPoint {
        if let cached = cache[url] { return cached }

        let center = detectLargestFaceCenter(in: cgImage)
        cache[url] = center
        return center
    }

    private func detectLargestFaceCenter(in image: CGImage) -> CGPoint {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return CGPoint(x: 0.5, y: 0.5)
        }

        guard let faces = request.results, !faces.isEmpty else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        // Pick the largest face (most prominent)
        guard let largest = faces.max(by: {
            $0.boundingBox.width * $0.boundingBox.height <
            $1.boundingBox.width * $1.boundingBox.height
        }) else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        // Vision coords: origin bottom-left → convert to UIKit top-left
        let centerX = largest.boundingBox.midX
        let centerY = 1.0 - largest.boundingBox.midY

        return CGPoint(x: centerX, y: centerY)
    }
}
