import Foundation

/// Bundles everything ChatKit needs for symbol messages.
public struct SymbolMessagePlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = SymbolMessageSender()

    public init(errorRouter: ErrorRouting) {
        self.renderer = SymbolMessageRenderer(errorRouter: errorRouter)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
