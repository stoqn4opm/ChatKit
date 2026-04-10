import Foundation

/// Bundles everything ChatKit needs for plain text messages.
public struct TextMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = TextMessageSender()

    public init(errorRouter: ErrorRouting) {
        self.renderer = TextMessageRenderer(errorRouter: errorRouter)
    }

    /// Convenience for `unregister(_:)` probing. Uses a no-op error router.
    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
