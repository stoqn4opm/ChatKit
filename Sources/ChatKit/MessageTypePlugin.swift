import Foundation

/// Groups everything ChatKit needs to fully support a message type:
/// a renderer (how to display it) and optionally a sender (how to create it).
///
/// Implement this protocol to add a new message type to ChatKit.
/// Then register it with `ChatViewBuilder.register(_:)` — one call
/// wires up all the pieces.
///
/// ```swift
/// // Custom audio message support:
/// public struct AudioMessagePlugin: MessageTypePlugin {
///     public let renderer: MessageRenderer = AudioMessageRenderer()
///     public let sender: MessageSender? = AudioMessageSender()
/// }
///
/// let builder = ChatViewBuilder.standard()
///     .register(AudioMessagePlugin())
///
/// // Later, to remove it:
/// builder.unregister(AudioMessagePlugin.self)
/// ```
///
/// Display-only types (e.g. date separators, typing indicators) return
/// `nil` for `sender`.
public protocol MessageTypePlugin {

    /// The renderer responsible for dequeueing and configuring cells
    /// for this message type. Required.
    var renderer: MessageRenderer { get }

    /// The sender that handles creation and publishing of this message
    /// type. Return `nil` for display-only types that the user never
    /// composes (date separators, typing indicators, system notices…).
    var sender: MessageSender? { get }
}
