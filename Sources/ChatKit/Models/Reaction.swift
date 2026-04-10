import Foundation

/// A single emoji reaction placed on a message by a participant.
public struct Reaction: Hashable, Sendable {

    /// The emoji string (e.g. "👍", "❤️", "😂").
    public let emoji: String

    /// Who placed the reaction.
    public let sender: ChatMessage.Sender

    /// When the reaction was added.
    public let timestamp: Date

    public init(emoji: String,
                sender: ChatMessage.Sender,
                timestamp: Date = Date()) {
        self.emoji = emoji
        self.sender = sender
        self.timestamp = timestamp
    }
}

/// Reactions grouped by emoji, with the list of senders who used each one.
///
/// Use `ChatMessage.reactionGroups` to compute this from the flat
/// `reactions` array.
public struct ReactionGroup: Hashable, Sendable {

    /// The emoji shared by all senders in this group.
    public let emoji: String

    /// The participants who used this emoji, in chronological order.
    public let senders: [ChatMessage.Sender]

    /// How many people reacted with this emoji.
    public var count: Int { senders.count }

    /// Returns `true` if the given sender is in this group.
    public func containsSender(_ sender: ChatMessage.Sender) -> Bool {
        senders.contains(sender)
    }

    public init(emoji: String, senders: [ChatMessage.Sender]) {
        self.emoji = emoji
        self.senders = senders
    }
}
