import UIKit

/// A cache layer for decoded images.
///
/// ChatKit ships with `DefaultImageCache` (an in-memory `NSCache`), but
/// you can implement this protocol to add disk persistence, size limits,
/// expiration policies, or to wrap a third-party cache. Multiple layers
/// can be composed using the decorator pattern:
///
/// ```swift
/// let l1 = MemoryImageCache()        // fast, limited capacity
/// let l2 = DiskImageCache()           // slow, large capacity
/// let cache = TieredImageCache(l1, l2) // checks L1 first, falls back to L2
/// ```
///
/// All methods are called from the main thread by default, but
/// implementations must be safe to call from any thread if the
/// `ImageLoading` implementation dispatches work off-main.
public protocol ImageCaching: AnyObject {

    /// Returns a previously cached image for the given key, or `nil` on a miss.
    func cachedImage(for key: String) -> UIImage?

    /// Stores a decoded image under the given key.
    func store(_ image: UIImage, for key: String)

    /// Removes the cached image for the given key, if any.
    func removeCachedImage(for key: String)

    /// Removes all cached images.
    func removeAll()
}
