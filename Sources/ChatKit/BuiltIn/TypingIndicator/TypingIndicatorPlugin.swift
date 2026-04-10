import Foundation

/// Bundles everything ChatKit needs for the typing indicator row.
/// Display-only — no sender.
public struct TypingIndicatorPlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = nil

    public init(errorRouter: ErrorRouting) {
        self.renderer = TypingIndicatorRenderer(errorRouter: errorRouter)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
