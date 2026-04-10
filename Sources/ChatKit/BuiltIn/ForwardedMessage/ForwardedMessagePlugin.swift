import Foundation

/// Bundles everything ChatKit needs for forwarded messages.
public struct ForwardedMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = ForwardedMessageSender()

    public init(bubbleConfig: BubbleConfiguration = .default) {
        let bodyRenderer = ForwardedMessageRenderer()
        self.renderer = BodyRendererAdapter(
            bodyRenderer: bodyRenderer, bubbleConfig: bubbleConfig)
    }

    public init() {
        self.init(bubbleConfig: .default)
    }
}
