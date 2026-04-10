import UIKit

/// Loads images from an `ImageSource` into a `UIImageView`.
///
/// ChatKit's `ImageBubbleCell` depends on this protocol — it never
/// decodes images itself. This makes the loading strategy fully
/// pluggable: the default `DefaultImageLoader` handles local files
/// and simple HTTP downloads with an in-memory cache, but any app can
/// inject Kingfisher, Nuke, SDWebImage, or a custom pipeline by
/// conforming to this protocol.
///
/// Implementations must handle:
/// - **`.local(URL)`**: Read from disk, decode, display.
/// - **`.remote(URL)`**: Download, cache, display.
///
/// The `.symbol` case is handled directly by the `SymbolBubbleCell`
/// and never reaches the image loader.
public protocol ImageLoading: AnyObject {

    /// Loads the image described by `source` into `imageView`.
    ///
    /// - The implementation should set `imageView.image` when loading
    ///   completes, on the main thread.
    /// - A placeholder may be shown immediately while loading is in
    ///   progress.
    /// - If the image view is reused before loading completes, the
    ///   previous load should be cancelled (see `cancelLoad`).
    func loadImage(from source: ImageSource, into imageView: UIImageView)

    /// Cancels any in-flight load for the given image view.
    ///
    /// Called from `prepareForReuse()` so that a recycled cell doesn't
    /// show a stale image from a previous index path.
    func cancelLoad(for imageView: UIImageView)
}
