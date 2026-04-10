import UIKit

public final class SymbolBubbleCell: UICollectionViewCell, BubbleProviding {

    public var contextMenuTargetView: UIView { bubbleView }

    public static let reuseID = "SymbolBubbleCell"

    // MARK: - Subviews

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let imageContainer: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.systemGray5
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
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
        bubbleView.addSubview(imageContainer)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.widthAnchor.constraint(equalToConstant: 200),
            bubbleView.heightAnchor.constraint(equalToConstant: 200),

            imageContainer.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 6),
            imageContainer.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 6),
            imageContainer.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -6),
            imageContainer.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6),

            metaLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
        ])

        outgoingConstraints = [
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            avatarView.trailingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -100),
        ]

        incomingConstraints = [
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 6),
            metaLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
        ]
    }

    // MARK: - Configure

    public func configure(with message: ChatMessage) {
        let isMe = message.sender.isMe

        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        NSLayoutConstraint.activate(isMe ? outgoingConstraints : incomingConstraints)

        bubbleView.backgroundColor = isMe ? .systemBlue : .secondarySystemBackground

        if case .symbol(let name) = message.imageSource {
            let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
            imageContainer.image = UIImage(systemName: name, withConfiguration: config)
            imageContainer.tintColor = isMe ? .white.withAlphaComponent(0.9) : .systemGray
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
        metaLabel.text = formatter.string(from: message.timestamp)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        avatarView.isHidden = true
        imageContainer.image = nil
    }
}
