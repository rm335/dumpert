import CoreImage

actor FaceDetectionService {
    static let shared = FaceDetectionService()

    // Cache: URL → normalized face center (UIKit coords, top-left origin)
    private var cache: [URL: CGPoint] = [:]
    private let maxCacheSize = 500

    /// Returns the center of the most prominent face in the image, or (0.5, 0.5) if none found.
    /// Result is in normalized UIKit coordinates (0,0 = top-left, 1,1 = bottom-right).
    func faceCenter(for url: URL, in cgImage: CGImage) -> CGPoint {
        if let cached = cache[url] { return cached }

        let center = detectLargestFaceCenter(in: cgImage)
        if cache.count >= maxCacheSize {
            // Evict ~25% of entries when full
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 4))
            for key in keysToRemove { cache.removeValue(forKey: key) }
        }
        cache[url] = center
        return center
    }

    // CIDetector is thread-safe after creation — cache to avoid per-call allocation
    private nonisolated(unsafe) static let faceDetectorLow = CIDetector(
        ofType: CIDetectorTypeFace,
        context: nil,
        options: [CIDetectorAccuracy: CIDetectorAccuracyLow]
    )

    private nonisolated func detectLargestFaceCenter(in image: CGImage) -> CGPoint {
        let ciImage = CIImage(cgImage: image)
        let detector = Self.faceDetectorLow

        guard let faces = detector?.features(in: ciImage) as? [CIFaceFeature], !faces.isEmpty else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        // Pick the largest face (most prominent)
        guard let largest = faces.max(by: {
            $0.bounds.width * $0.bounds.height <
            $1.bounds.width * $1.bounds.height
        }) else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        // CIDetector uses pixel coordinates with bottom-left origin → normalize to UIKit top-left
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let centerX = largest.bounds.midX / imageWidth
        let centerY = 1.0 - (largest.bounds.midY / imageHeight)

        return CGPoint(x: centerX, y: centerY)
    }
}
