import UIKit

public final class TextBubbleCell: UICollectionViewCell, BubbleProviding {

    public var contextMenuTargetView: UIView { bubbleView }

    public static let reuseID = "TextBubbleCell"

    // MARK: - Subviews

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    // MARK: - Constraint sets

    private var outgoingConstraints: [NSLayoutConstraint] = []
    private var incomingConstraints: [NSLayoutConstraint] = []

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
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(metaLabel)

        // Fixed constraints (always active)
        NSLayoutConstraint.activate([
            // Avatar size
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            // Bubble vertical
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.widthAnchor.constraint(
                lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.72),

            // Message inside bubble
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            // Meta label below bubble
            metaLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
        ])

        // Outgoing (right-aligned, no avatar)
        outgoingConstraints = [
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
            metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            avatarView.trailingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -100),
        ]

        // Incoming (left-aligned, with avatar)
        incomingConstraints = [
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 6),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            metaLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
        ]
    }

    // MARK: - Configure

    public func configure(with message: ChatMessage) {
        messageLabel.text = message.text

        let isMe = message.sender.isMe

        // Deactivate old, activate new
        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        if isMe {
            NSLayoutConstraint.activate(outgoingConstraints)
        } else {
            NSLayoutConstraint.activate(incomingConstraints)
        }

        // Colors
        bubbleView.backgroundColor = isMe ? .systemBlue : .secondarySystemBackground
        messageLabel.textColor = isMe ? .white : .label

        // Avatar
        avatarView.isHidden = isMe
        if !isMe {
            avatarView.configure(
                initial: String(message.sender.displayName.prefix(1)),
                color: message.sender.avatarColor
            )
        }

        // Meta text
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: message.timestamp)
        if isMe {
            let status = message.isRead ? "Read" : "Delivered"
            metaLabel.text = "\(status) · \(time)"
        } else {
            metaLabel.text = time
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        avatarView.isHidden = true
    }
}
