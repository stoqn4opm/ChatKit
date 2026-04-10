import CoreGraphics

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

    public init(
        avatarVisibility: AvatarVisibility = .incomingOnly,
        maxBubbleWidthFraction: CGFloat = 0.75
    ) {
        self.avatarVisibility = avatarVisibility
        self.maxBubbleWidthFraction = maxBubbleWidthFraction
    }

    /// Incoming-only avatars, 75% max bubble width.
    public static let `default` = BubbleConfiguration()
}
