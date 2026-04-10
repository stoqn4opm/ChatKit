import UIKit

/// The body view for forwarded messages.
///
/// Shows a "Forwarded from X" header with an arrow icon above the
/// message content (text or symbol image).
/// Installed inside `MessageBubbleCell` by `ForwardedMessageRenderer`.
final class ForwardedBodyView: UIView {

    // MARK: - Subviews

    let forwardIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        imageView.image = UIImage(
            systemName: "arrowshape.turn.up.right.fill",
            withConfiguration: config)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let forwardLabel: UILabel = {
        let label = UILabel()
        label.font = .italicSystemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let imageContainer: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.systemGray5
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    // MARK: - Constraint sets

    private var textConstraints: [NSLayoutConstraint] = []
    private var imageConstraints: [NSLayoutConstraint] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        addSubview(forwardIcon)
        addSubview(forwardLabel)
        addSubview(messageLabel)
        addSubview(imageContainer)

        NSLayoutConstraint.activate([
            forwardIcon.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            forwardIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            forwardIcon.widthAnchor.constraint(equalToConstant: 14),
            forwardIcon.heightAnchor.constraint(equalToConstant: 12),

            forwardLabel.centerYAnchor.constraint(equalTo: forwardIcon.centerYAnchor),
            forwardLabel.leadingAnchor.constraint(
                equalTo: forwardIcon.trailingAnchor, constant: 4),
            forwardLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -14),
        ])

        textConstraints = [
            messageLabel.topAnchor.constraint(
                equalTo: forwardLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ]

        imageConstraints = [
            imageContainer.topAnchor.constraint(
                equalTo: forwardLabel.bottomAnchor, constant: 6),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            imageContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            imageContainer.heightAnchor.constraint(equalToConstant: 160),
            imageContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ]
    }

    // MARK: - Configure

    func configure(with message: ChatMessage, isOutgoing: Bool) {
        NSLayoutConstraint.deactivate(textConstraints + imageConstraints)

        if case .symbol(let symbolName) = message.imageSource {
            imageContainer.isHidden = false
            messageLabel.isHidden = true
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
            imageContainer.image = UIImage(
                systemName: symbolName, withConfiguration: config)
            imageContainer.tintColor = isOutgoing
                ? .white.withAlphaComponent(0.9) : .systemGray
            NSLayoutConstraint.activate(imageConstraints)
        } else {
            imageContainer.isHidden = true
            messageLabel.isHidden = false
            messageLabel.text = message.text
            messageLabel.textColor = isOutgoing ? .white : .label
            NSLayoutConstraint.activate(textConstraints)
        }

        forwardIcon.tintColor = isOutgoing
            ? UIColor.white.withAlphaComponent(0.7) : .secondaryLabel
        forwardLabel.textColor = isOutgoing
            ? UIColor.white.withAlphaComponent(0.7) : .secondaryLabel

        if let originalSender = message.forwardedFrom {
            forwardLabel.text = "Forwarded from \(originalSender)"
        }
    }

    // MARK: - Reuse

    func reset() {
        NSLayoutConstraint.deactivate(textConstraints + imageConstraints)
        imageContainer.isHidden = true
        imageContainer.image = nil
        messageLabel.isHidden = false
        messageLabel.text = nil
        forwardLabel.text = nil
    }
}
