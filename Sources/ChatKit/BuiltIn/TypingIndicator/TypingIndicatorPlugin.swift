import Foundation

/// Bundles everything ChatKit needs for the typing indicator row.
/// Display-only — no sender.
public struct TypingIndicatorPlugin: MessageTypePlugin {
    public let renderer: MessageRenderer
    public let sender: MessageSender? = nil

    /// - Parameters:
    ///   - errorRouter: Receives ChatKit error notifications (e.g. cell-dequeue
    ///     failures). Defaults to `ChatKitErrorRouter`.
    ///   - showsAvatar: When `true`, the typing row renders a leading avatar
    ///     circle next to the bubble. Set `false` for clients that prefer a
    ///     plain bouncing-dots bubble. Defaults to `true` for backward
    ///     compatibility.
    public init(errorRouter: ErrorRouting, showsAvatar: Bool = true) {
        self.renderer = TypingIndicatorRenderer(errorRouter: errorRouter, showsAvatar: showsAvatar)
    }

    public init(showsAvatar: Bool = true) {
        self.init(errorRouter: ChatKitErrorRouter(), showsAvatar: showsAvatar)
    }
}
