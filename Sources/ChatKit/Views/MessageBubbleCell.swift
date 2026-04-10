import UIKit

/// The unified bubble cell used by all message types that go through the
/// `MessageBodyRenderer` system.
///
/// This cell provides the shared "chrome" — bubble background, avatar,
/// timestamp, read receipts, and incoming/outgoing layout switching. The
/// message-specific content lives in a **body view** created by the body
/// renderer and embedded in the cell's body container via `installBodyView(_:)`.
///
/// `MessageBubbleCell` is registered multiple times with different reuse
/// identifiers (one per body type) so that body views are never swapped
/// between incompatible renderers during cell reuse.
///
/// ## Layout structure
///
/// ```
/// contentView
/// ├── avatarView (30×30, bottom-aligned with bubble)
/// ├── bubbleView (rounded, colored)
/// │   └── bodyContainer
/// │       └── bodyView (installed by adapter, fills container)
/// └── metaLabel (below bubble)
/// ```
public final class MessageBubbleCell: UICollectionViewCell, BubbleProviding {

    public var contextMenuTargetView: UIView { bubbleView }

    // MARK: - Chrome subviews

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bodyContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let avatarView: AvatarView = {
        let avatar = AvatarView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Body

    /// The body view installed by the adapter. Nil until `installBodyView` is called.
    private(set) var bodyView: UIView?

    /// Called during `prepareForReuse` so the body renderer can clean up its view.
    var onPrepareBodyForReuse: (() -> Void)?

    // MARK: - Layout constraint sets

    /// Outgoing layout with avatar visible (avatar on the trailing side).
    private var outgoingWithAvatarConstraints: [NSLayoutConstraint] = []

    /// Outgoing layout with avatar hidden (bubble right-aligned, avatar off-screen).
    private var outgoingNoAvatarConstraints: [NSLayoutConstraint] = []

    /// Incoming layout with avatar visible (avatar on the leading side).
    private var incomingWithAvatarConstraints: [NSLayoutConstraint] = []

    /// Incoming layout with avatar hidden (bubble left-aligned, avatar off-screen).
    private var incomingNoAvatarConstraints: [NSLayoutConstraint] = []

    private var maxBubbleWidthConstraint: NSLayoutConstraint?

    // MARK: - Date formatter (reused)

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        contentView.addSubview(avatarView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(bodyContainer)
        contentView.addSubview(metaLabel)

        // Max bubble width — default 75%, can be updated via updateMaxBubbleWidth
        let maxWidth = bubbleView.widthAnchor.constraint(
            lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        maxBubbleWidthConstraint = maxWidth

        NSLayoutConstraint.activate([
            // Avatar size
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            // Bubble vertical
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            maxWidth,

            // Body fills bubble
            bodyContainer.topAnchor.constraint(equalTo: bubbleView.topAnchor),
            bodyContainer.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            bodyContainer.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            bodyContainer.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            // Meta label below bubble
            metaLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
        ])

        // --- Four layout variants ---

        // Outgoing + avatar (avatar on trailing side)
        outgoingWithAvatarConstraints = [
            avatarView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),
            bubbleView.trailingAnchor.constraint(
                equalTo: avatarView.leadingAnchor, constant: -6),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
            metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
        ]

        // Outgoing + no avatar (bubble right-aligned, avatar off-screen)
        outgoingNoAvatarConstraints = [
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
            metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            avatarView.trailingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: -100),
        ]

        // Incoming + avatar (avatar on leading side)
        incomingWithAvatarConstraints = [
            avatarView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 8),
            bubbleView.leadingAnchor.constraint(
                equalTo: avatarView.trailingAnchor, constant: 6),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            metaLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
        ]

        // Incoming + no avatar (bubble left-aligned, avatar off-screen)
        incomingNoAvatarConstraints = [
            bubbleView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            metaLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            avatarView.trailingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: -100),
        ]
    }

    // MARK: - Body Installation

    /// Installs a body view into the cell. Called once per cell lifetime
    /// (before the first `configure`). The view is then reused on each
    /// subsequent configure call — it is never removed.
    func installBodyView(_ view: UIView) {
        bodyView?.removeFromSuperview()
        bodyView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        bodyContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: bodyContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor),
        ])
    }

    // MARK: - Configure

    /// Configures the cell's chrome (avatar, meta, colors, alignment).
    ///
    /// The body view is configured separately by the body renderer — this
    /// method only handles the shared bubble frame.
    func configure(with message: ChatMessage,
                   avatarVisibility: BubbleConfiguration.AvatarVisibility) {
        let isOutgoing = message.sender.isMe

        // Determine avatar visibility
        let showAvatar: Bool
        switch avatarVisibility {
        case .incomingOnly: showAvatar = !isOutgoing
        case .outgoingOnly: showAvatar = isOutgoing
        case .both:         showAvatar = true
        case .none:         showAvatar = false
        }

        // Deactivate all layout constraints, then activate the right set
        NSLayoutConstraint.deactivate(
            outgoingWithAvatarConstraints + outgoingNoAvatarConstraints
            + incomingWithAvatarConstraints + incomingNoAvatarConstraints)

        if isOutgoing {
            NSLayoutConstraint.activate(
                showAvatar ? outgoingWithAvatarConstraints : outgoingNoAvatarConstraints)
        } else {
            NSLayoutConstraint.activate(
                showAvatar ? incomingWithAvatarConstraints : incomingNoAvatarConstraints)
        }

        // Bubble colour
        bubbleView.backgroundColor = isOutgoing
            ? .systemBlue : .secondarySystemBackground

        // Avatar
        avatarView.isHidden = !showAvatar
        if showAvatar {
            avatarView.configure(
                initial: String(message.sender.displayName.prefix(1)),
                color: message.sender.avatarColor)
        }

        // Meta text (time + optional read receipt)
        let time = Self.timeFormatter.string(from: message.timestamp)
        if isOutgoing {
            let status = message.isRead ? "Read" : "Delivered"
            metaLabel.text = "\(status) · \(time)"
        } else {
            metaLabel.text = time
        }
    }

    // MARK: - Reuse

    public override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(
            outgoingWithAvatarConstraints + outgoingNoAvatarConstraints
            + incomingWithAvatarConstraints + incomingNoAvatarConstraints)
        avatarView.isHidden = true
        onPrepareBodyForReuse?()
    }
}
