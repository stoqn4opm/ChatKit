import UIKit

/// The body view for reply messages.
///
/// Shows a quoted-message block (coloured bar + sender name + truncated
/// text) above the reply text. The quote container fires `onQuoteTapped`
/// when tapped.
///
/// Installed inside `MessageBubbleCell` by `ReplyMessageRenderer`.
final class ReplyBodyView: UIView {

    /// Called when the user taps the quoted-message block. The parameter
    /// is the original `ChatMessage` being replied to.
    var onQuoteTapped: ((ChatMessage) -> Void)?

    /// Stored so the tap gesture can access it.
    private(set) var quotedMessage: ChatMessage?

    // MARK: - Subviews

    let quoteContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    let quoteBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let quoteSenderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let quoteTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
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

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        addSubview(quoteContainer)
        quoteContainer.addSubview(quoteBar)
        quoteContainer.addSubview(quoteSenderLabel)
        quoteContainer.addSubview(quoteTextLabel)
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            quoteContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            quoteContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            quoteContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

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
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])

        let quoteTap = UITapGestureRecognizer(
            target: self, action: #selector(quoteContainerTapped))
        quoteContainer.addGestureRecognizer(quoteTap)
    }

    @objc private func quoteContainerTapped() {
        guard let quoted = quotedMessage else { return }
        onQuoteTapped?(quoted)
    }

    // MARK: - Configure

    func configure(with message: ChatMessage, isOutgoing: Bool) {
        quotedMessage = message.replyingTo?.value
        messageLabel.text = message.text
        messageLabel.textColor = isOutgoing ? .white : .label

        quoteContainer.backgroundColor = isOutgoing
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor.systemGray4.withAlphaComponent(0.4)

        if let original = message.replyingTo?.value {
            let senderColor = original.sender.avatarColor
            quoteBar.backgroundColor = senderColor
            quoteSenderLabel.text = original.sender.displayName
            quoteSenderLabel.textColor = isOutgoing ? .white : senderColor
            quoteTextLabel.text = original.text ?? "(image)"
            quoteTextLabel.textColor = isOutgoing
                ? UIColor.white.withAlphaComponent(0.8)
                : .secondaryLabel
        }
    }

    // MARK: - Reuse

    func reset() {
        quotedMessage = nil
        onQuoteTapped = nil
        messageLabel.text = nil
        quoteSenderLabel.text = nil
        quoteTextLabel.text = nil
    }
}
