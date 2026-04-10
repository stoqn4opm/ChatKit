import UIKit

/// Renders plain text messages (no reply, no forward, no image).
///
/// Returns a `TextBodyView` that is embedded in `MessageBubbleCell` via
/// the `BodyRendererAdapter`.
public final class TextMessageRenderer: MessageBodyRenderer {

    public var bodyReuseIdentifier: String { "Text" }

    public init() {}

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        return msg.text != nil
            && msg.imageSource == nil
            && msg.replyingTo == nil
            && msg.forwardedFrom == nil
    }

    public func createBodyView() -> UIView { TextBodyView() }

    public func configureBody(_ bodyView: UIView,
                              with message: ChatMessage,
                              isOutgoing: Bool,
                              eventHandler: ((MessageBodyEvent) -> Void)?) {
        guard let body = bodyView as? TextBodyView else { return }
        body.messageLabel.text = message.text
        body.messageLabel.textColor = isOutgoing ? .white : .label
    }

    public func prepareBodyForReuse(_ bodyView: UIView) {
        guard let body = bodyView as? TextBodyView else { return }
        body.messageLabel.text = nil
    }
}
