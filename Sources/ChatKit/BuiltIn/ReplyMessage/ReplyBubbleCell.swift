import UIKit

/// A message bubble that shows a quoted original message above the reply text.
public final class ReplyBubbleCell: UICollectionViewCell, BubbleProviding {

    public var contextMenuTargetView: UIView { bubbleView }

    public static let reuseID = "ReplyBubbleCell"

    /// Called when the user taps the quoted-message block. The parameter
    /// is the original `ChatMessage` being replied to.
    var onQuoteTapped: ((ChatMessage) -> Void)?

    /// Stored so the tap gesture can access it.
    private var quotedMessage: ChatMessage?

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let quoteContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let quoteBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let quoteSenderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let quoteTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        contentView.addSubview(avatarView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(quoteContainer)
        quoteContainer.addSubview(quoteBar)
        quoteContainer.addSubview(quoteSenderLabel)
        quoteContainer.addSubview(quoteTextLabel)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.widthAnchor.constraint(
                lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),

            quoteContainer.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            quoteContainer.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 10),
            quoteContainer.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -10),

            quoteBar.leadingAnchor.constraint(equalTo: quoteContainer.leadingAnchor, constant: 8),
            quoteBar.topAnchor.constraint(equalTo: quoteContainer.topAnchor, constant: 6),
            quoteBar.bottomAnchor.constraint(equalTo: quoteContainer.bottomAnchor, constant: -6),
            quoteBar.widthAnchor.constraint(equalToConstant: 3),

            quoteSenderLabel.topAnchor.constraint(equalTo: quoteContainer.topAnchor, constant: 6),
            quoteSenderLabel.leadingAnchor.constraint(equalTo: quoteBar.trailingAnchor, constant: 8),
            quoteSenderLabel.trailingAnchor.constraint(equalTo: quoteContainer.trailingAnchor, constant: -8),

            quoteTextLabel.topAnchor.constraint(equalTo: quoteSenderLabel.bottomAnchor, constant: 2),
            quoteTextLabel.leadingAnchor.constraint(equalTo: quoteBar.trailingAnchor, constant: 8),
            quoteTextLabel.trailingAnchor.constraint(equalTo: quoteContainer.trailingAnchor, constant: -8),
            quoteTextLabel.bottomAnchor.constraint(equalTo: quoteContainer.bottomAnchor, constant: -6),

            messageLabel.topAnchor.constraint(equalTo: quoteContainer.bottomAnchor, constant: 6),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            metaLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
        ])

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

        let quoteTap = UITapGestureRecognizer(target: self, action: #selector(quoteContainerTapped))
        quoteContainer.addGestureRecognizer(quoteTap)
        quoteContainer.isUserInteractionEnabled = true
    }

    @objc private func quoteContainerTapped() {
        guard let quoted = quotedMessage else { return }
        onQuoteTapped?(quoted)
    }

    public func configure(with message: ChatMessage) {
        quotedMessage = message.replyingTo?.value
        messageLabel.text = message.text

        let isMe = message.sender.isMe

        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        if isMe {
            NSLayoutConstraint.activate(outgoingConstraints)
        } else {
            NSLayoutConstraint.activate(incomingConstraints)
        }

        bubbleView.backgroundColor = isMe ? .systemBlue : .secondarySystemBackground
        messageLabel.textColor = isMe ? .white : .label

        quoteContainer.backgroundColor = isMe
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor.systemGray4.withAlphaComponent(0.4)

        if let original = message.replyingTo?.value {
            let senderColor = original.sender.avatarColor
            quoteBar.backgroundColor = senderColor
            quoteSenderLabel.text = original.sender.displayName
            quoteSenderLabel.textColor = isMe ? .white : senderColor
            quoteTextLabel.text = original.text ?? "(image)"
            quoteTextLabel.textColor = isMe
                ? UIColor.white.withAlphaComponent(0.8)
                : .secondaryLabel
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
        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        avatarView.isHidden = true
        quotedMessage = nil
        onQuoteTapped = nil
    }
}
