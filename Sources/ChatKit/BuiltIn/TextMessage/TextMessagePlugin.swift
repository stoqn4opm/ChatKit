import Foundation

/// Bundles everything ChatKit needs for plain text messages.
public struct TextMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = TextMessageSender()

    public init(bubbleConfig: BubbleConfiguration = .default) {
        let bodyRenderer = TextMessageRenderer()
        self.renderer = BodyRendererAdapter(
            bodyRenderer: bodyRenderer, bubbleConfig: bubbleConfig)
    }

    /// Convenience for `unregister(_:)` probing.
    public init() {
        self.init(bubbleConfig: .default)
    }
}
