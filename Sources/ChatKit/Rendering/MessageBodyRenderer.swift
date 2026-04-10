import UIKit

/// Events emitted by body views and forwarded through the bubble cell
/// to ChatKit's Combine publishers.
///
/// Body renderers fire events via the `eventHandler` closure passed to
/// `configureBody(_:with:isOutgoing:eventHandler:)`. ChatKit's builder
/// wires these through to the appropriate publisher on `ChatCollectionView`.
public enum MessageBodyEvent: Sendable {

    /// The user tapped the quoted-message block inside a reply bubble.
    /// The associated value is the original message being replied to.
    case quoteTapped(ChatMessage)
}

/// Describes how a message type renders its body content inside the
/// unified `MessageBubbleCell`.
///
/// Unlike `MessageRenderer` (which provides a complete `UICollectionViewCell`),
/// a `MessageBodyRenderer` returns a plain `UIView` that is embedded in
/// `MessageBubbleCell`'s body container. The bubble cell handles all shared
/// chrome: avatar, timestamp, read receipts, alignment, and bubble background.
///
/// Each body renderer creates a reusable body view once; subsequent calls
/// reconfigure that same view for a different message — analogous to how
/// `UICollectionViewCell` reuse works.
///
/// ## How it plugs in
///
/// You never add a `MessageBodyRenderer` directly to the renderer chain.
/// Instead, register it via a `MessageTypePlugin` whose initializer wraps
/// it in a `BodyRendererAdapter`:
///
/// ```swift
/// public struct AudioMessagePlugin: MessageTypePlugin {
///     public let renderer: MessageRenderer
///     public let sender: MessageSender?
///
///     public init(bubbleConfig: BubbleConfiguration = .default) {
///         let body = AudioBodyRenderer()
///         self.renderer = BodyRendererAdapter(
///             bodyRenderer: body, bubbleConfig: bubbleConfig)
///         self.sender = AudioMessageSender()
///     }
/// }
/// ```
///
/// ## Minimal implementation
///
/// ```swift
/// final class AudioBodyRenderer: MessageBodyRenderer {
///     var bodyReuseIdentifier: String { "Audio" }
///
///     func canRender(_ item: ChatItem) -> Bool { /* ... */ }
///     func createBodyView() -> UIView { AudioBodyView() }
///
///     func configureBody(_ bodyView: UIView,
///                        with message: ChatMessage,
///                        isOutgoing: Bool,
///                        eventHandler: ((MessageBodyEvent) -> Void)?) {
///         guard let body = bodyView as? AudioBodyView else { return }
///         body.configure(with: message, isOutgoing: isOutgoing)
///     }
///
///     func prepareBodyForReuse(_ bodyView: UIView) {
///         guard let body = bodyView as? AudioBodyView else { return }
///         body.reset()
///     }
/// }
/// ```
public protocol MessageBodyRenderer: AnyObject {

    /// A unique identifier for this body type. Used as part of the cell's
    /// reuse identifier so that body views of different types are never
    /// swapped during cell reuse.
    ///
    /// Example: `"Text"`, `"Image"`, `"Reply"`.
    var bodyReuseIdentifier: String { get }

    /// Returns `true` if this renderer knows how to display the given item.
    func canRender(_ item: ChatItem) -> Bool

    /// Creates a fresh body view. Called once per cell instance — the view
    /// is then reused across `configureBody` calls. Always return a new
    /// instance (never share views between cells).
    func createBodyView() -> UIView

    /// Configures the body view for a specific message.
    ///
    /// Only called when `canRender` has already returned `true`.
    ///
    /// - Parameters:
    ///   - bodyView: The view originally returned by `createBodyView()`.
    ///   - message: The message to display.
    ///   - isOutgoing: `true` when the message is from `.me`.
    ///   - eventHandler: A closure the body can call to emit events
    ///     (e.g. quote taps). May be `nil` if no listener is registered.
    func configureBody(_ bodyView: UIView,
                       with message: ChatMessage,
                       isOutgoing: Bool,
                       eventHandler: ((MessageBodyEvent) -> Void)?)

    /// Resets the body view for reuse. Called from
    /// `MessageBubbleCell.prepareForReuse()`.
    func prepareBodyForReuse(_ bodyView: UIView)
}
