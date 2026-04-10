import UIKit

/// Renders reply messages (quoted original above the reply text).
///
/// Returns a `ReplyBodyView` embedded in `MessageBubbleCell` via
/// the `BodyRendererAdapter`. Quote-tap events are forwarded through
/// `MessageBodyEvent.quoteTapped`.
public final class ReplyMessageRenderer: MessageBodyRenderer {

    public var bodyReuseIdentifier: String { "Reply" }

    public init() {}

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        return msg.replyingTo != nil
    }

    public func createBodyView() -> UIView { ReplyBodyView() }

    public func configureBody(_ bodyView: UIView,
                              with message: ChatMessage,
                              isOutgoing: Bool,
                              eventHandler: ((MessageBodyEvent) -> Void)?) {
        guard let body = bodyView as? ReplyBodyView else { return }
        body.configure(with: message, isOutgoing: isOutgoing)

        // Wire quote tap → event handler
        body.onQuoteTapped = { quotedMessage in
            eventHandler?(.quoteTapped(quotedMessage))
        }
    }

    public func prepareBodyForReuse(_ bodyView: UIView) {
        guard let body = bodyView as? ReplyBodyView else { return }
        body.reset()
    }
}
