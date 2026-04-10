import UIKit

/// The contract for a custom "scroll to bottom" button in ChatKit.
///
/// Any `UIView` that conforms to this protocol can replace the built-in
/// `ScrollToBottomView`. ChatKit owns the lifecycle — it creates the view
/// via the builder closure in `ScrollToBottomConfiguration`, adds it as a
/// subview, and drives `unreadCount` and visibility. The view is responsible
/// for its own intrinsic size and internal layout.
///
/// ## Minimal implementation
///
/// ```swift
/// final class MyScrollButton: UIView, ScrollToBottomProviding {
///     var onTap: (() -> Void)?
///     var unreadCount: Int = 0 { didSet { /* update your badge */ } }
///
///     override init(frame: CGRect) {
///         super.init(frame: frame)
///         // ... build your UI, add a tap gesture that calls onTap?() ...
///     }
/// }
/// ```
public protocol ScrollToBottomProviding: UIView {

    /// ChatKit calls this closure when the user taps the button.
    /// The view must fire it on tap — ChatKit handles the actual scrolling
    /// and unread-count reset.
    var onTap: (() -> Void)? { get set }

    /// The number of messages that arrived while the user was scrolled away.
    /// ChatKit updates this value whenever new items are appended.
    /// The view should display it however it likes (badge, label, etc.)
    /// and may hide the indicator when the count is zero.
    var unreadCount: Int { get set }
}

// MARK: - Position

/// Describes where the scroll-to-bottom button sits relative to the chat view.
public struct ScrollToBottomPosition: Equatable, Sendable {

    /// Horizontal placement within the chat view.
    public enum HorizontalAlignment: Sendable {
        case leading
        case center
        case trailing
    }

    /// Horizontal placement. Default is `.trailing`.
    public var alignment: HorizontalAlignment

    /// Distance from the bottom edge of the chat view. Default is `12`.
    public var bottomInset: CGFloat

    /// Distance from the leading or trailing edge (ignored for `.center`).
    /// Default is `12`.
    public var sideInset: CGFloat

    public init(
        alignment: HorizontalAlignment = .trailing,
        bottomInset: CGFloat = 12,
        sideInset: CGFloat = 12
    ) {
        self.alignment = alignment
        self.bottomInset = bottomInset
        self.sideInset = sideInset
    }

    /// Bottom-trailing with 12 pt insets — the most common chat app placement.
    public static let `default` = ScrollToBottomPosition()
}

// MARK: - Configuration

/// Bundles the scroll-to-bottom view builder closure and its position.
///
/// Pass a custom configuration to `ChatViewBuilder.scrollToBottom(_:)` or
/// directly to `ChatCollectionView` to change the button's appearance
/// and/or placement.
///
/// ```swift
/// // Custom look, bottom-left:
/// let config = ScrollToBottomConfiguration(
///     position: ScrollToBottomPosition(alignment: .leading),
///     viewFactory: { MyCustomScrollButton() }
/// )
/// let builder = ChatViewBuilder.standard()
///     .scrollToBottom(config)
/// ```
public struct ScrollToBottomConfiguration {

    /// Where to place the button.
    public var position: ScrollToBottomPosition

    /// Creates the button view. Called once when the chat view is set up.
    /// Return a fresh instance each time — ChatKit owns its lifecycle.
    public var viewFactory: () -> any ScrollToBottomProviding

    public init(
        position: ScrollToBottomPosition = .default,
        viewFactory: @escaping () -> any ScrollToBottomProviding = { ScrollToBottomView() }
    ) {
        self.position = position
        self.viewFactory = viewFactory
    }

    /// The built-in pill button at bottom-trailing.
    public static let `default` = ScrollToBottomConfiguration()
}
