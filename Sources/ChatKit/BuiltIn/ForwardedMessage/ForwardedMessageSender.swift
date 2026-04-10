import Foundation
import Combine

/// Handles sending forwarded messages.
public final class ForwardedMessageSender: MessageSender {
    public init() {}

    public func canSend(_ action: SendAction) -> Bool {
        if case .forward = action { return true }
        return false
    }

    public func send(_ action: SendAction,
                     via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) {
        guard case .forward(let original) = action else { return }

        let forwarded = ChatMessage.forwarded(original, by: .me)
        subject.send(.append(items: [.message(forwarded)], scrollToBottom: true))

        ReadReceiptScheduler.schedule(for: forwarded, via: subject)
    }
}
