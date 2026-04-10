import UIKit

/// Renders forwarded messages ("Forwarded from X" header above content).
///
/// Returns a `ForwardedBodyView` embedded in `MessageBubbleCell` via
/// the `BodyRendererAdapter`.
public final class ForwardedMessageRenderer: MessageBodyRenderer {

    public var bodyReuseIdentifier: String { "Forwarded" }

    public init() {}

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        return msg.forwardedFrom != nil
    }

    public func createBodyView() -> UIView { ForwardedBodyView() }

    public func configureBody(_ bodyView: UIView,
                              with message: ChatMessage,
                              isOutgoing: Bool,
                              eventHandler: ((MessageBodyEvent) -> Void)?) {
        guard let body = bodyView as? ForwardedBodyView else { return }
        body.configure(with: message, isOutgoing: isOutgoing)
    }

    public func prepareBodyForReuse(_ bodyView: UIView) {
        guard let body = bodyView as? ForwardedBodyView else { return }
        body.reset()
    }
}
