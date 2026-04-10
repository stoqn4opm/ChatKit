import UIKit

/// A simple in-memory image cache backed by `NSCache`.
///
/// This is ChatKit's default `ImageCaching` implementation. It
/// automatically evicts images under memory pressure (via `NSCache`'s
/// built-in cost tracking) and is safe to use from any thread.
///
/// For production apps that need a disk layer, implement `ImageCaching`
/// with a two-tier strategy or use a library like Kingfisher/Nuke
/// behind the same protocol.
public final class DefaultImageCache: ImageCaching {

    private let cache = NSCache<NSString, UIImage>()

    /// Creates a new in-memory cache.
    ///
    /// - Parameters:
    ///   - countLimit: Maximum number of images to hold. `0` means no limit
    ///                 (the OS decides when to evict). Default is `100`.
    ///   - totalCostLimit: Maximum total cost (in bytes) before eviction
    ///                     kicks in. `0` means no limit. Default is `50 MB`.
    public init(countLimit: Int = 100, totalCostLimit: Int = 50 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    // MARK: - ImageCaching

    public func cachedImage(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    public func store(_ image: UIImage, for key: String) {
        let cost = imageCost(image)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    public func removeCachedImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    // MARK: - Helpers

    /// Estimates the in-memory byte cost of a decoded `UIImage`.
    private func imageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
