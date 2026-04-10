import Foundation

/// Bundles everything ChatKit needs for SF Symbol messages.
public struct SymbolMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = SymbolMessageSender()

    public init(bubbleConfig: BubbleConfiguration = .default) {
        let bodyRenderer = SymbolMessageRenderer()
        self.renderer = BodyRendererAdapter(
            bodyRenderer: bodyRenderer, bubbleConfig: bubbleConfig)
    }

    public init() {
        self.init(bubbleConfig: .default)
    }
}
