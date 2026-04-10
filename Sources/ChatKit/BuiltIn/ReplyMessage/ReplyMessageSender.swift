import Foundation
import Combine

/// Handles sending reply messages (quoted original + reply text).
public final class ReplyMessageSender: MessageSender {
    public init() {}

    public func canSend(_ action: SendAction) -> Bool {
        if case .reply = action { return true }
        return false
    }

    public func send(_ action: SendAction,
                     via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) {
        guard case .reply(let original, let text) = action else { return }

        let reply = ChatMessage.reply(to: original, text: text, from: .me)
        subject.send(.append(items: [.message(reply)], scrollToBottom: true))

        ReadReceiptScheduler.schedule(for: reply, via: subject)
    }
}
