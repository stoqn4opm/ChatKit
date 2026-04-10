import Foundation
import Combine

/// Shared utility that simulates a read receipt arriving after a delay.
/// Used by all `MessageSender` implementations to flip `isRead` to `true`.
public enum ReadReceiptScheduler {

    public static func schedule(for message: ChatMessage,
                                via subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>,
                                delay: TimeInterval = 1.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let updated = ChatMessage(
                id: message.id,
                text: message.text,
                imageSource: message.imageSource,
                sender: message.sender,
                timestamp: message.timestamp,
                isRead: true,
                replyingTo: message.replyingTo,
                forwardedFrom: message.forwardedFrom
            )
            subject.send(.update(items: [.message(updated)]))
        }
    }
}
