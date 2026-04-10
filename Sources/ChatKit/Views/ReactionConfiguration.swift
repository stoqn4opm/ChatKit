import Foundation

/// Controls the reaction UI on message bubbles.
///
/// Pass a custom configuration to `ChatViewBuilder.standard(reactionConfig:)`
/// or set it on the builder before calling `buildChatView()`.
///
/// ```swift
/// let builder = ChatViewBuilder.standard(
///     reactionConfig: ReactionConfiguration(maxVisibleReactions: 5)
/// )
/// ```
public struct ReactionConfiguration: Equatable, Sendable {

    /// Master toggle for the entire reaction system.
    ///
    /// When `false`, no reaction pills, "+" buttons, or quick-reaction
    /// bars are shown on any message bubble. Existing reactions on the
    /// model are preserved but invisible. Default is `true`.
    public var isEnabled: Bool

    /// Maximum number of distinct emoji groups shown inline on the bubble.
    /// When the message has more distinct emoji than this, a "+N" pill is
    /// shown instead of the overflowing groups.
    ///
    /// Default is `3`.
    public var maxVisibleReactions: Int

    /// The emojis displayed in the quick-reaction bar, in order.
    /// The last position in the bar is always a "…" button that opens
    /// the system emoji keyboard.
    ///
    /// Default: `["👍", "❤️", "😂", "😮", "😢", "🙏"]`.
    public var quickReactions: [String]

    /// Whether to show the small "+" button on message bubbles that
    /// lets users add reactions without long-pressing.
    ///
    /// Default is `true`.
    public var showAddButton: Bool

    public init(
        isEnabled: Bool = true,
        maxVisibleReactions: Int = 3,
        quickReactions: [String] = ["👍", "❤️", "😂", "😮", "😢", "🙏"],
        showAddButton: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.maxVisibleReactions = maxVisibleReactions
        self.quickReactions = quickReactions
        self.showAddButton = showAddButton
    }

    /// Reactions enabled, 3 visible reactions, default quick-reaction set,
    /// add button enabled.
    public static let `default` = ReactionConfiguration()

    /// Reactions completely disabled — no pills or add buttons shown.
    public static let disabled = ReactionConfiguration(isEnabled: false)
}
