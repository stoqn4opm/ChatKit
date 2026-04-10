import Foundation
import Combine

/// Handles sending symbol messages (SF Symbol name).
public final class SymbolMessageSender: MessageSender {
    public init() {}

    public func canSend(_ action: SendAction) -> Bool {
        if case .symbol = action { return true }
        return false
    }

    public func send(_ action: SendAction,
                     via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) {
        guard case .symbol(let name) = action else { return }

        let outgoing = ChatMessage.symbol(name, from: .me, isRead: false)
        subject.send(.append(items: [.message(outgoing)], scrollToBottom: true))

        ReadReceiptScheduler.schedule(for: outgoing, via: subject)
    }
}
