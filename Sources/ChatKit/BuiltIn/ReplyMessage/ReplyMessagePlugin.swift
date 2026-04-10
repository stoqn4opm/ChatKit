import Foundation

/// Bundles everything ChatKit needs for reply messages.
public struct ReplyMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = ReplyMessageSender()

    public init(errorRouter: ErrorRouting) {
        self.renderer = ReplyMessageRenderer(errorRouter: errorRouter)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
