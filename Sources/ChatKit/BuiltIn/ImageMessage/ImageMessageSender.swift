import Foundation
import Combine

/// Handles sending real image messages (local files and remote URLs).
///
/// SF Symbol sends are handled by `SymbolMessageSender` instead.
public final class ImageMessageSender: MessageSender {
    public init() {}

    public func canSend(_ action: SendAction) -> Bool {
        if case .image = action { return true }
        return false
    }

    public func send(_ action: SendAction,
                     via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) {
        guard case .image(let source) = action else { return }

        let outgoing = ChatMessage.image(source, from: .me, isRead: false)
        subject.send(.append(items: [.message(outgoing)], scrollToBottom: true))

        ReadReceiptScheduler.schedule(for: outgoing, via: subject)
    }
}
