import UIKit

/// Bundles everything ChatKit needs for date separator rows.
/// Display-only — no sender.
public struct DateSeparatorPlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = nil

    public init(errorRouter: ErrorRouting, textColor: UIColor? = nil, pillColor: UIColor? = nil) {
        self.renderer = DateSeparatorRenderer(errorRouter: errorRouter, textColor: textColor, pillColor: pillColor)
    }

    public init() {
        self.init(errorRouter: ChatKitErrorRouter())
    }
}
