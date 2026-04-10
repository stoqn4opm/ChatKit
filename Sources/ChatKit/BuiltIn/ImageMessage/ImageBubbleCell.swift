import UIKit

/// A message bubble that displays a real image (local file or remote URL).
///
/// Unlike `SymbolBubbleCell` which renders lightweight SF Symbols,
/// this cell loads full images through the `ImageLoading` abstraction,
/// supporting lazy loading, caching, and memory-efficient reuse.
public final class ImageBubbleCell: UICollectionViewCell, BubbleProviding {

    public var contextMenuTargetView: UIView { bubbleView }

    public static let reuseID = "ImageBubbleCell"

    /// The image loader injected by the renderer. Set before `configure`.
    var imageLoader: ImageLoading?

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
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.systemGray5
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
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
    private var isObservingImage = false

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
        bubbleView.addSubview(loadingIndicator)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.widthAnchor.constraint(equalToConstant: 220),
            bubbleView.heightAnchor.constraint(equalToConstant: 220),

            imageContainer.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4),
            imageContainer.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),
            imageContainer.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4),
            imageContainer.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4),

            loadingIndicator.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),

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

        // Load the image through the abstraction
        if let source = message.imageSource {
            loadingIndicator.startAnimating()
            imageContainer.addObserver(self, forKeyPath: "image", options: [.new], context: nil)
            isObservingImage = true
            imageLoader?.loadImage(from: source, into: imageContainer)
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

    // MARK: - KVO for loading indicator

    public override func observeValue(forKeyPath keyPath: String?,
                                       of object: Any?,
                                       change: [NSKeyValueChangeKey: Any]?,
                                       context: UnsafeMutableRawPointer?) {
        if keyPath == "image", imageContainer.image != nil, isObservingImage {
            loadingIndicator.stopAnimating()
            imageContainer.removeObserver(self, forKeyPath: "image")
            isObservingImage = false
        }
    }

    // MARK: - Reuse

    public override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(outgoingConstraints + incomingConstraints)
        avatarView.isHidden = true
        imageLoader?.cancelLoad(for: imageContainer)
        loadingIndicator.stopAnimating()
        if isObservingImage {
            imageContainer.removeObserver(self, forKeyPath: "image")
            isObservingImage = false
        }
        imageContainer.image = nil
    }
}
