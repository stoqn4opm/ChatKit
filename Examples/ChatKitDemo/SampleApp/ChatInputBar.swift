import UIKit

protocol ChatInputBarDelegate: AnyObject {
    func chatInputBar(_ bar: ChatInputBar, didSendMessage text: String)
    func chatInputBarDidTapAttachment(_ bar: ChatInputBar)
}

// Default implementation so attachment is optional for consumers
extension ChatInputBarDelegate {
    func chatInputBarDidTapAttachment(_ bar: ChatInputBar) {}
}

final class ChatInputBar: UIView {

    weak var delegate: ChatInputBarDelegate?

    // MARK: - Subviews

    private let attachmentButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Type a message..."
        field.borderStyle = .none
        field.font = .systemFont(ofSize: 16)
        field.returnKeyType = .send
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupViews()
        setupActions()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        addSubview(separator)
        addSubview(attachmentButton)
        addSubview(containerView)
        containerView.addSubview(textField)
        addSubview(sendButton)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            attachmentButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            attachmentButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            attachmentButton.widthAnchor.constraint(equalToConstant: 36),
            attachmentButton.heightAnchor.constraint(equalToConstant: 36),

            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        attachmentButton.addTarget(self, action: #selector(attachmentTapped), for: .touchUpInside)
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.delegate = self
    }

    // MARK: - Actions

    @objc private func sendTapped() {
        sendCurrentText()
    }

    @objc private func attachmentTapped() {
        delegate?.chatInputBarDidTapAttachment(self)
    }

    @objc private func textChanged() {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendButton.isEnabled = hasText
    }

    private func sendCurrentText() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        delegate?.chatInputBar(self, didSendMessage: text)
        textField.text = nil
        sendButton.isEnabled = false
    }
}

extension ChatInputBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendCurrentText()
        return false
    }
}
