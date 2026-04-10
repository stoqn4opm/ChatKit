import UIKit

/// A reference-typed box so `ChatMessage` (a value type) can point to a quoted original
/// without creating a recursive struct.
public final class QuotedMessage: Hashable, @unchecked Sendable {
    public let value: ChatMessage

    public init(_ message: ChatMessage) { self.value = message }

    public static func == (lhs: QuotedMessage, rhs: QuotedMessage) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

public struct ChatMessage: Hashable, Sendable {
    public let id: UUID
    public let text: String?
    public let imageSource: ImageSource?
    public let sender: Sender
    public let timestamp: Date
    public let isRead: Bool

    /// If this message is a reply, the original message being replied to (boxed to avoid recursion).
    public let replyingTo: QuotedMessage?

    /// If this message was forwarded, the name of the original sender.
    public let forwardedFrom: String?

    public init(id: UUID, text: String?, imageSource: ImageSource?,
                sender: Sender, timestamp: Date, isRead: Bool,
                replyingTo: QuotedMessage?, forwardedFrom: String?) {
        self.id = id
        self.text = text
        self.imageSource = imageSource
        self.sender = sender
        self.timestamp = timestamp
        self.isRead = isRead
        self.replyingTo = replyingTo
        self.forwardedFrom = forwardedFrom
    }

    public enum Sender: Hashable, Sendable {
        case me
        case other(name: String)

        public var displayName: String {
            switch self {
            case .me: return "Me"
            case .other(let name): return name
            }
        }

        public var isMe: Bool {
            if case .me = self { return true }
            return false
        }

        public var avatarColor: UIColor {
            switch self {
            case .me: return .systemBlue
            case .other(let name):
                // Deterministic color from name
                let hash = abs(name.hashValue)
                let colors: [UIColor] = [
                    .systemPurple, .systemOrange, .systemTeal,
                    .systemPink, .systemGreen, .systemIndigo,
                ]
                return colors[hash % colors.count]
            }
        }
    }

    // MARK: - Convenience Initializers

    public static func text(_ text: String, from sender: Sender, at date: Date = Date(),
                            isRead: Bool = false) -> ChatMessage {
        ChatMessage(id: UUID(), text: text, imageSource: nil,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: nil)
    }

    public static func symbol(_ sfSymbolName: String, from sender: Sender, at date: Date = Date(),
                              isRead: Bool = false) -> ChatMessage {
        ChatMessage(id: UUID(), text: nil, imageSource: .symbol(sfSymbolName),
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: nil)
    }

    public static func image(_ source: ImageSource, from sender: Sender, at date: Date = Date(),
                             isRead: Bool = false) -> ChatMessage {
        ChatMessage(id: UUID(), text: nil, imageSource: source,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: nil)
    }

    public static func reply(to original: ChatMessage, text: String, from sender: Sender,
                             at date: Date = Date(), isRead: Bool = false) -> ChatMessage {
        ChatMessage(id: UUID(), text: text, imageSource: nil,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: QuotedMessage(original), forwardedFrom: nil)
    }

    public static func forwarded(_ original: ChatMessage, by sender: Sender,
                                 at date: Date = Date(), isRead: Bool = false) -> ChatMessage {
        ChatMessage(id: UUID(), text: original.text, imageSource: original.imageSource,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: original.sender.displayName)
    }
}
