import Foundation
import Combine

/// Composes an ordered list of `MessageSender`s into a single sender.
///
/// `SenderChain` itself conforms to `MessageSender` — it iterates through
/// its children and delegates to the first one that can handle the action.
/// This keeps individual senders decoupled: they never hold a `next`
/// reference and don't know they're part of a chain.
public final class SenderChain: MessageSender {

    private let senders: [MessageSender]
    private let subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>
    private let errorRouter: ErrorRouting

    public init(senders: [MessageSender],
                subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>,
                errorRouter: ErrorRouting) {
        precondition(!senders.isEmpty, "SenderChain needs at least one sender")
        self.senders = senders
        self.subject = subject
        self.errorRouter = errorRouter
    }

    // MARK: - MessageSender

    /// Returns `true` if any child sender can handle the action.
    public func canSend(_ action: SendAction) -> Bool {
        senders.contains { $0.canSend(action) }
    }

    /// Route a send action through the children.
    ///
    /// Delegates to the first sender whose `canSend(_:)` returns `true`.
    /// If no sender matches, the error is routed through the injected
    /// `ErrorRouting` and the action is dropped.
    public func send(_ action: SendAction,
                     via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) {
        for sender in senders where sender.canSend(action) {
            sender.send(action, via: subject)
            return
        }
        errorRouter.route(.senderNotFound(action: action))
    }

    // MARK: - Convenience

    /// Sends using the subject this chain was initialized with.
    public func send(_ action: SendAction) {
        send(action, via: subject)
    }
}
