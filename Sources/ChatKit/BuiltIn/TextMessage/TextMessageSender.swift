import Foundation
import Combine

/// Handles sending plain text messages.
public final class TextMessageSender: MessageSender {
    public init() {}

    public func canSend(_ action: SendAction) -> Bool {
        if case .text = action { return true }
        return false
    }

    public func send(_ action: SendAction,
                     via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) {
        guard case .text(let text) = action else { return }

        let outgoing = ChatMessage.text(text, from: .me, isRead: false)
        subject.send(.append(items: [.message(outgoing)], scrollToBottom: true))

        ReadReceiptScheduler.schedule(for: outgoing, via: subject)
    }
}
