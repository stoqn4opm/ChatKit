import Foundation

/// Bundles everything ChatKit needs for real image messages
/// (local files and remote URLs).
///
/// This plugin uses `ImageLoading` to lazily load and cache images.
/// For SF Symbol messages, see `SymbolMessagePlugin`.
public struct ImageMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = ImageMessageSender()

    public init(errorRouter: ErrorRouting, imageLoader: ImageLoading) {
        self.renderer = ImageMessageRenderer(errorRouter: errorRouter, imageLoader: imageLoader)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter(), imageLoader: DefaultImageLoader())
    }
}
