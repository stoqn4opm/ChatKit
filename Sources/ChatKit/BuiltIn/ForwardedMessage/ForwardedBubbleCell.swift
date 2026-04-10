import UIKit

/// A message bubble showing a "Forwarded from X" header above the message content.
public final class ForwardedBubbleCell: UICollectionViewCell, BubbleProviding {

    public var contextMenuTargetView: UIView { bubbleView }

    public static let reuseID = "ForwardedBubbleCell"

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let forwardIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        imageView.image = UIImage(systemName: "arrowshape.turn.up.right.fill", withConfiguration: config)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let forwardLabel: UILabel = {
        let label = UILabel()
        label.font = .italicSystemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let imageContainer: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.systemGray5
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
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

    private var outgoingConstraints: [NSLayoutConstraint] = []
    private var incomingConstraints: [NSLayoutConstraint] = []
    private var textConstraints: [NSLayoutConstraint] = []
    private var imageConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        contentView.addSubview(avatarView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(forwardIcon)
        bubbleView.addSubview(forwardLabel)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(imageContainer)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.widthAnchor.constraint(
                lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.72),

            forwardIcon.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            forwardIcon.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            forwardIcon.widthAnchor.constraint(equalToConstant: 14),
            forwardIcon.heightAnchor.constraint(equalToConstant: 12),

            forwardLabel.centerYAnchor.constraint(equalTo: forwardIcon.centerYAnchor),
            forwardLabel.leadingAnchor.constraint(equalTo: forwardIcon.trailingAnchor, constant: 4),
            forwardLabel.trailingAnchor.constraint(lessThanOrEqualTo: bubbleView.trailingAnchor, constant: -14),

            metaLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
        ])

        textConstraints = [
            messageLabel.topAnchor.constraint(equalTo: forwardLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
        ]

        imageConstraints = [
            imageContainer.topAnchor.constraint(equalTo: forwardLabel.bottomAnchor, constant: 6),
            imageContainer.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 6),
            imageContainer.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -6),
            imageContainer.heightAnchor.constraint(equalToConstant: 160),
            imageContainer.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6),
        ]

        outgoingConstraints = [
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
            metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            avatarView.trailingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -100),
        ]

        incomingConstraints = [
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 6),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            metaLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
        ]
    }

    public func configure(with message: ChatMessage) {
        let isMe = message.sender.isMe

        NSLayoutConstraint.deactivate(
            outgoingConstraints + incomingConstraints + textConstraints + imageConstraints
        )

        if isMe {
            NSLayoutConstraint.activate(outgoingConstraints)
        } else {
            NSLayoutConstraint.activate(incomingConstraints)
        }

        if case .symbol(let symbolName) = message.imageSource {
            imageContainer.isHidden = false
            messageLabel.isHidden = true
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
            imageContainer.image = UIImage(systemName: symbolName, withConfiguration: config)
            imageContainer.tintColor = isMe ? .white.withAlphaComponent(0.9) : .systemGray
            NSLayoutConstraint.activate(imageConstraints)
        } else {
            imageContainer.isHidden = true
            messageLabel.isHidden = false
            messageLabel.text = message.text
            NSLayoutConstraint.activate(textConstraints)
        }

        bubbleView.backgroundColor = isMe ? .systemBlue : .secondarySystemBackground
        messageLabel.textColor = isMe ? .white : .label
        forwardIcon.tintColor = isMe ? UIColor.white.withAlphaComponent(0.7) : .secondaryLabel
        forwardLabel.textColor = isMe ? UIColor.white.withAlphaComponent(0.7) : .secondaryLabel

        if let originalSender = message.forwardedFrom {
            forwardLabel.text = "Forwarded from \(originalSender)"
        }

        avatarView.isHidden = isMe
        if !isMe {
            avatarView.configure(
                initial: String(message.sender.displayName.prefix(1)),
                color: message.sender.avatarColor
            )
        }

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
        NSLayoutConstraint.deactivate(
            outgoingConstraints + incomingConstraints + textConstraints + imageConstraints
        )
        avatarView.isHidden = true
        imageContainer.isHidden = true
        imageContainer.image = nil
        messageLabel.isHidden = false
    }
}
