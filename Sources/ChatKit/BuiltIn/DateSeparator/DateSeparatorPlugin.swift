import Foundation

/// Bundles everything ChatKit needs for date separator rows.
/// Display-only — no sender.
public struct DateSeparatorPlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = nil

    public init(errorRouter: ErrorRouting) {
        self.renderer = DateSeparatorRenderer(errorRouter: errorRouter)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
