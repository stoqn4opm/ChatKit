import UIKit

/// Renders SF Symbol messages (no reply, no forward).
///
/// Returns a `SymbolBodyView` embedded in `MessageBubbleCell` via
/// the `BodyRendererAdapter`.
public final class SymbolMessageRenderer: MessageBodyRenderer {

    public var bodyReuseIdentifier: String { "Symbol" }

    public init() {}

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        if case .symbol = msg.imageSource { } else { return false }
        return msg.replyingTo == nil && msg.forwardedFrom == nil
    }

    public func createBodyView() -> UIView { SymbolBodyView() }

    public func configureBody(_ bodyView: UIView,
                              with message: ChatMessage,
                              isOutgoing: Bool,
                              eventHandler: ((MessageBodyEvent) -> Void)?) {
        guard let body = bodyView as? SymbolBodyView else { return }

        if case .symbol(let name) = message.imageSource {
            let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
            body.imageContainer.image = UIImage(
                systemName: name, withConfiguration: config)
            body.imageContainer.tintColor = isOutgoing
                ? .white.withAlphaComponent(0.9) : .systemGray
        }
    }

    public func prepareBodyForReuse(_ bodyView: UIView) {
        guard let body = bodyView as? SymbolBodyView else { return }
        body.imageContainer.image = nil
    }
}
