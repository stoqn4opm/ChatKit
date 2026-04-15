import UIKit

/// Controls the visual chrome of `MessageBubbleCell`.
///
/// Pass a custom configuration to `ChatViewBuilder.bubbleConfiguration(_:)`
/// to change avatar visibility and other bubble-level settings globally.
///
/// ```swift
/// let builder = ChatViewBuilder.standard(
///     bubbleConfig: BubbleConfiguration(avatarVisibility: .both)
/// )
/// ```
public struct BubbleConfiguration: Equatable, Sendable {

    /// Controls when avatars are shown on message bubbles.
    public enum AvatarVisibility: Sendable {
        /// Show avatars on incoming messages only (default behaviour,
        /// matching most consumer chat apps).
        case incomingOnly

        /// Show avatars on outgoing messages only.
        case outgoingOnly

        /// Show avatars on all messages.
        case both

        /// Never show avatars on message bubbles.
        case none
    }

    /// Which message sides display an avatar. Default is `.incomingOnly`.
    public var avatarVisibility: AvatarVisibility

    /// Maximum bubble width as a fraction of the collection view width.
    /// Default is `0.75`. Body views that specify their own fixed width
    /// constraints (e.g. image bubbles) may be narrower than this.
    public var maxBubbleWidthFraction: CGFloat

    /// Background colour for outgoing (sent) message bubbles.
    /// Default is `.systemBlue`.
    public var sentBubbleColor: UIColor

    /// Background colour for incoming (received) message bubbles.
    /// Default is `.secondarySystemBackground`.
    public var receivedBubbleColor: UIColor

    /// Text colour for message content inside bubbles.
    /// When set, all body renderers use this colour for primary text
    /// regardless of outgoing/incoming. Default is `nil`, which falls
    /// back to `.white` for outgoing and `.label` for incoming.
    public var messageTextColor: UIColor?

    public init(
        avatarVisibility: AvatarVisibility = .incomingOnly,
        maxBubbleWidthFraction: CGFloat = 0.75,
        sentBubbleColor: UIColor = .systemBlue,
        receivedBubbleColor: UIColor = .secondarySystemBackground,
        messageTextColor: UIColor? = nil
    ) {
        self.avatarVisibility = avatarVisibility
        self.maxBubbleWidthFraction = maxBubbleWidthFraction
        self.sentBubbleColor = sentBubbleColor
        self.receivedBubbleColor = receivedBubbleColor
        self.messageTextColor = messageTextColor
    }

    /// Incoming-only avatars, 75% max bubble width.
    public static let `default` = BubbleConfiguration()
}
