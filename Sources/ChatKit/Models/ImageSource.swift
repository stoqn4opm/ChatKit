import Foundation

/// Describes where the pixels for an image message live.
///
/// `ChatMessage` stores an `ImageSource` instead of raw image data,
/// so images are loaded on demand and released when the cell scrolls
/// off screen — keeping memory usage independent of conversation length.
///
/// - `.symbol`: An SF Symbol name (lightweight, system-provided glyph).
/// - `.local`:  A `file://` URL pointing to an image on disk.
/// - `.remote`: An `https://` URL to fetch from a server.
public enum ImageSource: Sendable, Hashable {

    /// A system SF Symbol name (e.g. "photo.fill").
    /// Rendered via `UIImage(systemName:)` — no loading or caching needed.
    case symbol(String)

    /// A file URL pointing to an image already on disk
    /// (e.g. copied from the photo library into the app's cache directory).
    case local(URL)

    /// A remote URL to download (e.g. `https://api.example.com/images/abc.jpg`).
    /// The image loader downloads it, writes to disk cache, then displays.
    case remote(URL)
}
