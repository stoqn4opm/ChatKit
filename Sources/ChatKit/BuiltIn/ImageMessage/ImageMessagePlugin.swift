import Foundation

/// Bundles everything ChatKit needs for real image messages
/// (local files and remote URLs).
///
/// This plugin uses `ImageLoading` to lazily load and cache images.
/// For SF Symbol messages, see `SymbolMessagePlugin`.
public struct ImageMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = ImageMessageSender()

    public init(imageLoader: ImageLoading, bubbleConfig: BubbleConfiguration = .default) {
        let bodyRenderer = ImageMessageRenderer(imageLoader: imageLoader)
        self.renderer = BodyRendererAdapter(
            bodyRenderer: bodyRenderer, bubbleConfig: bubbleConfig)
    }

    public init() {
        self.init(imageLoader: DefaultImageLoader(), bubbleConfig: .default)
    }
}
