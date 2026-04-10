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

    // MARK: - Identity-based Hashable/Equatable
    //
    // Two messages are "the same" when they share the same `id`.
    // This lets NSDiffableDataSource match an updated message (e.g.
    // with new reactions or read-receipt changes) to the existing
    // snapshot entry so `reconfigureItems` can refresh the cell
    // in-place instead of treating it as a different item.

    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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

    /// Emoji reactions placed on this message by chat participants.
    public let reactions: [Reaction]

    public init(id: UUID, text: String?, imageSource: ImageSource?,
                sender: Sender, timestamp: Date, isRead: Bool,
                replyingTo: QuotedMessage?, forwardedFrom: String?,
                reactions: [Reaction] = []) {
        self.id = id
        self.text = text
        self.imageSource = imageSource
        self.sender = sender
        self.timestamp = timestamp
        self.isRead = isRead
        self.replyingTo = replyingTo
        self.forwardedFrom = forwardedFrom
        self.reactions = reactions
    }

    // MARK: - Reactions

    /// Reactions grouped by emoji, sorted by first-reaction time.
    public var reactionGroups: [ReactionGroup] {
        var groupOrder: [String] = []
        var sendersByEmoji: [String: [Sender]] = [:]
        for reaction in reactions {
            if sendersByEmoji[reaction.emoji] == nil {
                groupOrder.append(reaction.emoji)
            }
            sendersByEmoji[reaction.emoji, default: []].append(reaction.sender)
        }
        return groupOrder.compactMap { emoji in
            guard let senders = sendersByEmoji[emoji] else { return nil }
            return ReactionGroup(emoji: emoji, senders: senders)
        }
    }

    /// Returns a copy of this message with the given reaction added.
    public func addingReaction(_ reaction: Reaction) -> ChatMessage {
        ChatMessage(id: id, text: text, imageSource: imageSource,
                    sender: sender, timestamp: timestamp, isRead: isRead,
                    replyingTo: replyingTo, forwardedFrom: forwardedFrom,
                    reactions: reactions + [reaction])
    }

    /// Returns a copy of this message with all reactions by the given
    /// sender for the given emoji removed.
    public func removingReaction(emoji: String, from reactionSender: Sender) -> ChatMessage {
        let filtered = reactions.filter {
            !($0.emoji == emoji && $0.sender == reactionSender)
        }
        return ChatMessage(id: id, text: text, imageSource: imageSource,
                           sender: sender, timestamp: timestamp, isRead: isRead,
                           replyingTo: replyingTo, forwardedFrom: forwardedFrom,
                           reactions: filtered)
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
                            isRead: Bool = false, reactions: [Reaction] = []) -> ChatMessage {
        ChatMessage(id: UUID(), text: text, imageSource: nil,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: nil, reactions: reactions)
    }

    public static func symbol(_ sfSymbolName: String, from sender: Sender, at date: Date = Date(),
                              isRead: Bool = false, reactions: [Reaction] = []) -> ChatMessage {
        ChatMessage(id: UUID(), text: nil, imageSource: .symbol(sfSymbolName),
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: nil, reactions: reactions)
    }

    public static func image(_ source: ImageSource, from sender: Sender, at date: Date = Date(),
                             isRead: Bool = false, reactions: [Reaction] = []) -> ChatMessage {
        ChatMessage(id: UUID(), text: nil, imageSource: source,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: nil, reactions: reactions)
    }

    public static func reply(to original: ChatMessage, text: String, from sender: Sender,
                             at date: Date = Date(), isRead: Bool = false,
                             reactions: [Reaction] = []) -> ChatMessage {
        ChatMessage(id: UUID(), text: text, imageSource: nil,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: QuotedMessage(original), forwardedFrom: nil,
                    reactions: reactions)
    }

    public static func forwarded(_ original: ChatMessage, by sender: Sender,
                                 at date: Date = Date(), isRead: Bool = false,
                                 reactions: [Reaction] = []) -> ChatMessage {
        ChatMessage(id: UUID(), text: original.text, imageSource: original.imageSource,
                    sender: sender, timestamp: date, isRead: isRead,
                    replyingTo: nil, forwardedFrom: original.sender.displayName,
                    reactions: reactions)
    }
}
