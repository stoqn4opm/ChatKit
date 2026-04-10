import Foundation

/// Bundles everything ChatKit needs for reply messages.
public struct ReplyMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = ReplyMessageSender()

    public init(bubbleConfig: BubbleConfiguration = .default) {
        let bodyRenderer = ReplyMessageRenderer()
        self.renderer = BodyRendererAdapter(
            bodyRenderer: bodyRenderer, bubbleConfig: bubbleConfig)
    }

    public init() {
        self.init(bubbleConfig: .default)
    }
}
