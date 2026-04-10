import UIKit

/// Renders real image messages (local files and remote URLs).
///
/// This renderer handles `.local` and `.remote` image sources.
/// SF Symbol images are handled by `SymbolMessageRenderer` instead.
///
/// Returns an `ImageBodyView` embedded in `MessageBubbleCell` via
/// the `BodyRendererAdapter`.
public final class ImageMessageRenderer: NSObject, MessageBodyRenderer {

    public var bodyReuseIdentifier: String { "Image" }

    private let imageLoader: ImageLoading

    public init(imageLoader: ImageLoading) {
        self.imageLoader = imageLoader
        super.init()
    }

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item,
              let source = msg.imageSource else { return false }
        switch source {
        case .local, .remote:
            return msg.replyingTo == nil && msg.forwardedFrom == nil
        case .symbol:
            return false
        }
    }

    public func createBodyView() -> UIView { ImageBodyView() }

    public func configureBody(_ bodyView: UIView,
                              with message: ChatMessage,
                              isOutgoing: Bool,
                              eventHandler: ((MessageBodyEvent) -> Void)?) {
        guard let body = bodyView as? ImageBodyView else { return }

        if let source = message.imageSource {
            body.loadingIndicator.startAnimating()
            body.imageContainer.addObserver(
                self, forKeyPath: "image", options: [.new], context: nil)
            body.isObservingImage = true
            imageLoader.loadImage(from: source, into: body.imageContainer)
        }
    }

    public func prepareBodyForReuse(_ bodyView: UIView) {
        guard let body = bodyView as? ImageBodyView else { return }
        imageLoader.cancelLoad(for: body.imageContainer)
        body.loadingIndicator.stopAnimating()
        if body.isObservingImage {
            body.imageContainer.removeObserver(self, forKeyPath: "image")
            body.isObservingImage = false
        }
        body.imageContainer.image = nil
    }

    // MARK: - KVO for loading indicator

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "image",
              let imageView = object as? UIImageView,
              imageView.image != nil else { return }

        // Walk up to find the ImageBodyView
        var current: UIView? = imageView.superview
        while let view = current {
            if let body = view as? ImageBodyView, body.isObservingImage {
                body.loadingIndicator.stopAnimating()
                imageView.removeObserver(self, forKeyPath: "image")
                body.isObservingImage = false
                break
            }
            current = view.superview
        }
    }
}
