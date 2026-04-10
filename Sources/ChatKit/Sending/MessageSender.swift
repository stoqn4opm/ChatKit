import Foundation
import Combine

/// Describes a user-initiated send action.
/// Each case maps to a message type. To add a new sendable type,
/// add a case here and create a matching `MessageSender` implementation.
public enum SendAction: Sendable {
    case text(String)
    case symbol(String)                         // SF Symbol name
    case image(ImageSource)                     // Photo from disk or remote URL
    case reply(to: ChatMessage, text: String)
    case forward(ChatMessage)
}

/// Describes how to handle a single send action type.
///
/// Each message type implements this protocol. The `SenderChain` iterates
/// through senders in order; the first one whose `canSend(_:)` returns
/// `true` handles the action.
///
/// Senders are simple, standalone strategy objects — they know nothing
/// about chains or ordering. The chain-walking logic lives in `SenderChain`.
///
/// To add a new sendable type, create a class conforming to `MessageSender`
/// and register it via `ChatViewBuilder.register(_:)`.
public protocol MessageSender: AnyObject {

    /// Returns `true` if this sender handles the given action.
    func canSend(_ action: SendAction) -> Bool

    /// Execute the send: create the message and publish it.
    /// Only called when `canSend` has already returned `true`.
    func send(_ action: SendAction,
              via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>)
}
