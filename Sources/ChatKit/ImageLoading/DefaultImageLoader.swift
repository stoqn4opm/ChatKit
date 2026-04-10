import UIKit
import ObjectiveC

/// ChatKit's built-in image loader.
///
/// Handles `.local` and `.remote` image sources with an in-memory cache.
/// For production apps, you'll likely want to replace this with a loader
/// backed by Kingfisher, Nuke, or SDWebImage — just conform to
/// `ImageLoading` and inject it via `ChatViewBuilder`.
public final class DefaultImageLoader: ImageLoading {

    private let cache: ImageCaching
    private let session: URLSession

    /// Associates a running `URLSessionDataTask` with a `UIImageView`
    /// so we can cancel it on reuse.
    private static var taskKey = 0

    /// Creates a loader with the given cache and URL session.
    ///
    /// - Parameters:
    ///   - cache: The cache layer to check before loading. Defaults to
    ///            `DefaultImageCache()`.
    ///   - session: The URL session for remote downloads. Defaults to
    ///              `.shared`.
    public init(cache: ImageCaching = DefaultImageCache(),
                session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    // MARK: - ImageLoading

    public func loadImage(from source: ImageSource, into imageView: UIImageView) {
        cancelLoad(for: imageView)

        let key = cacheKey(for: source)

        // Cache hit — display immediately
        if let cached = cache.cachedImage(for: key) {
            imageView.image = cached
            return
        }

        switch source {
        case .symbol:
            // Symbols are handled by SymbolBubbleCell, not this loader.
            break

        case .local(let fileURL):
            loadLocal(fileURL, key: key, into: imageView)

        case .remote(let remoteURL):
            loadRemote(remoteURL, key: key, into: imageView)
        }
    }

    public func cancelLoad(for imageView: UIImageView) {
        associatedTask(for: imageView)?.cancel()
        setAssociatedTask(nil, for: imageView)
    }

    // MARK: - Local

    private func loadLocal(_ url: URL, key: String, into imageView: UIImageView) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak imageView] in
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else { return }

            self?.cache.store(image, for: key)

            DispatchQueue.main.async {
                imageView?.image = image
            }
        }
    }

    // MARK: - Remote

    private func loadRemote(_ url: URL, key: String, into imageView: UIImageView) {
        let task = session.dataTask(with: url) { [weak self, weak imageView] data, _, error in
            guard error == nil,
                  let data = data,
                  let image = UIImage(data: data) else { return }

            self?.cache.store(image, for: key)

            DispatchQueue.main.async {
                imageView?.image = image
            }
        }

        setAssociatedTask(task, for: imageView)
        task.resume()
    }

    // MARK: - Cache Key

    private func cacheKey(for source: ImageSource) -> String {
        switch source {
        case .symbol(let name):   return "symbol:\(name)"
        case .local(let url):     return "local:\(url.absoluteString)"
        case .remote(let url):    return "remote:\(url.absoluteString)"
        }
    }

    // MARK: - Associated Task

    private func associatedTask(for imageView: UIImageView) -> URLSessionDataTask? {
        objc_getAssociatedObject(imageView, &Self.taskKey) as? URLSessionDataTask
    }

    private func setAssociatedTask(_ task: URLSessionDataTask?, for imageView: UIImageView) {
        objc_setAssociatedObject(imageView, &Self.taskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
