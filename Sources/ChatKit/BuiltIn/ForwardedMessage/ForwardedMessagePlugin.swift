import Foundation

/// Bundles everything ChatKit needs for forwarded messages.
public struct ForwardedMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = ForwardedMessageSender()

    public init(errorRouter: ErrorRouting) {
        self.renderer = ForwardedMessageRenderer(errorRouter: errorRouter)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
