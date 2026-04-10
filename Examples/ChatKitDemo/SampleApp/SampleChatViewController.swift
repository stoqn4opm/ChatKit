import UIKit
import Combine
import ChatKit

final class SampleChatViewController: UIViewController {

    // MARK: - Dependencies

    private let chatService = MockChatService()
    private var chatView: ChatCollectionView<ChatItem>!
    private let inputBar = ChatInputBar()

    /// Builder-produced sender chain.
    private var senderChain: SenderChain!

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chat"
        navigationItem.largeTitleDisplayMode = .never

        let builder = ChatViewBuilder.standard(reactionConfig: .disabled)
        // To add a custom message type in your app:
        //   builder.prependRenderer(AudioMessageRenderer())
        //   builder.prependSender(AudioMessageSender())

        chatView = builder.buildChatView()
        senderChain = builder.buildSenderChain(subject: chatService.updateSubject)

        setupChatView()
        setupInputBar()
        setupLayout()
        bindReactive()
        chatService.loadInitialMessages()
        chatService.startAmbientChat()
        chatService.startRemoteReactions()
    }

    // MARK: - Setup

    private func setupChatView() {
        chatView.translatesAutoresizingMaskIntoConstraints = false

        chatView.setContextMenuProvider { [weak self] item in
            self?.contextMenu(for: item)
        }

        view.addSubview(chatView)
    }

    private func setupInputBar() {
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.delegate = self
        view.addSubview(inputBar)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
    }

    /// The floating quick-reaction bar shown when the user taps "+".
    private var quickReactionBar: QuickReactionBar?

    /// The message currently targeted by the quick-reaction bar.
    private var quickReactionTarget: ChatMessage?

    /// Hidden text field used to present the system emoji keyboard.
    private lazy var emojiTextField: EmojiTextField = {
        let field = EmojiTextField()
        field.delegate = self
        field.isHidden = true
        view.addSubview(field)
        return field
    }()

    // MARK: - Reactive Bindings

    private func bindReactive() {
        chatView.bind(to: chatService.updates)

        chatView.paginationRequested
            .sink { [weak self] _ in self?.chatService.loadOlderMessages() }
            .store(in: &cancellables)

        chatView.itemSelected
            .sink { [weak self] item in self?.handleItemSelected(item) }
            .store(in: &cancellables)

        chatView.quoteTapped
            .sink { [weak self] originalMessage in
                self?.chatView.scrollToItem(.message(originalMessage))
            }
            .store(in: &cancellables)

        // Reaction pill tapped → toggle the current user's reaction
        chatView.reactionTapped
            .sink { [weak self] message, emoji in
                self?.chatService.toggleReaction(emoji: emoji, on: message)
            }
            .store(in: &cancellables)

        // "+" button tapped → show the quick-reaction bar
        chatView.addReactionTapped
            .sink { [weak self] message in
                self?.showQuickReactionBar(for: message)
            }
            .store(in: &cancellables)
    }

    /// A translucent backdrop behind the bar that dismisses on tap.
    private var quickReactionDimView: UIView?

    // MARK: - Quick Reaction Bar

    private func showQuickReactionBar(for message: ChatMessage) {
        dismissQuickReactionBar()

        quickReactionTarget = message

        // Find the cell's bubble so we can pin the bar above it.
        let messageItem = ChatItem.message(message)
        guard let indexPath = chatView.indexPath(for: messageItem),
              let cell = chatView.underlyingCollectionView.cellForItem(at: indexPath)
                  as? BubbleProviding else {
            return
        }

        let bubbleView = cell.contextMenuTargetView

        // Dim view — covers the screen and dismisses on tap.
        let dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        dimView.frame = view.bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        dimView.addGestureRecognizer(dismissTap)
        view.addSubview(dimView)
        quickReactionDimView = dimView

        // Create and configure the bar.
        let bar = QuickReactionBar()
        bar.configure(emojis: ReactionConfiguration.default.quickReactions)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.alpha = 0
        bar.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        view.addSubview(bar)

        // Convert the bubble's frame into our view's coordinate space.
        let bubbleFrameInView = bubbleView.convert(bubbleView.bounds, to: view)

        // Position: centred horizontally on the bubble, above it.
        // Clamp so the bar doesn't overflow screen edges.
        let barHalfWidth: CGFloat = 140
        let centerX = min(
            max(bubbleFrameInView.midX, barHalfWidth + 8),
            view.bounds.width - barHalfWidth - 8)

        NSLayoutConstraint.activate([
            bar.centerXAnchor.constraint(
                equalTo: view.leadingAnchor, constant: centerX),
            bar.bottomAnchor.constraint(
                equalTo: view.topAnchor,
                constant: bubbleFrameInView.minY - 6),
        ])

        bar.onEmojiSelected = { [weak self] emoji in
            guard let self, let target = self.quickReactionTarget else { return }
            self.chatService.toggleReaction(emoji: emoji, on: target)
            self.dismissQuickReactionBar()
        }

        bar.onExpandRequested = { [weak self] in
            self?.showEmojiKeyboard()
        }

        quickReactionBar = bar

        UIView.animate(withDuration: 0.2, delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5) {
            bar.alpha = 1
            bar.transform = .identity
        }
    }

    @objc private func dimViewTapped() {
        dismissQuickReactionBar()
        emojiTextField.resignFirstResponder()
    }

    private func dismissQuickReactionBar(keepTarget: Bool = false) {
        guard let bar = quickReactionBar else { return }
        UIView.animate(withDuration: 0.15, animations: {
            bar.alpha = 0
            bar.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }, completion: { _ in
            bar.removeFromSuperview()
        })
        quickReactionDimView?.removeFromSuperview()
        quickReactionDimView = nil
        quickReactionBar = nil
        if !keepTarget {
            quickReactionTarget = nil
        }
    }

    // MARK: - Emoji Keyboard

    private func showEmojiKeyboard() {
        // Dismiss the quick bar but keep the target message so we
        // can apply the selected emoji from the keyboard.
        dismissQuickReactionBar(keepTarget: true)
        emojiTextField.text = ""
        emojiTextField.becomeFirstResponder()
    }

    // MARK: - Context Menu

    private func contextMenu(for item: ChatItem) -> UIMenu? {
        guard case .message(let message) = item else { return nil }

        var actions: [UIAction] = []

        actions.append(UIAction(
            title: "Reply",
            image: UIImage(systemName: "arrowshape.turn.up.left")
        ) { [weak self] _ in
            self?.senderChain.send(.reply(to: message, text: "Replying to this!"))
            self?.chatService.scheduleIncomingReply()
        })

        actions.append(UIAction(
            title: "Forward",
            image: UIImage(systemName: "arrowshape.turn.up.right")
        ) { [weak self] _ in
            self?.senderChain.send(.forward(message))
        })

        if let text = message.text {
            actions.append(UIAction(
                title: "Copy",
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                UIPasteboard.general.string = text
            })
        }

        actions.append(UIAction(
            title: "React",
            image: UIImage(systemName: "face.smiling")
        ) { [weak self] _ in
            self?.showQuickReactionBar(for: message)
        })

        if !message.reactions.isEmpty {
            actions.append(UIAction(
                title: "Show Reactions",
                image: UIImage(systemName: "heart.text.square")
            ) { [weak self] _ in
                let detail = ReactionsDetailViewController(message: message)
                self?.present(detail, animated: true)
            })
        }

        actions.append(UIAction(
            title: "Unsend",
            image: UIImage(systemName: "arrow.uturn.backward"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.chatService.unsend(item)
        })

        return UIMenu(title: "", children: actions)
    }

    // MARK: - Selection

    private func handleItemSelected(_ item: ChatItem) {
        guard case .message(let msg) = item else { return }
        let text = msg.text ?? "(image)"
        let alert = UIAlertController(title: "Tapped Message",
                                      message: text,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ChatInputBarDelegate

extension SampleChatViewController: ChatInputBarDelegate {
    func chatInputBar(_ bar: ChatInputBar, didSendMessage text: String) {
        senderChain.send(.text(text))
        chatService.scheduleIncomingReply()
    }

    func chatInputBarDidTapAttachment(_ bar: ChatInputBar) {
        let sheet = UIAlertController(title: "Send Message",
                                      message: "Choose a message type",
                                      preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "📷 Image", style: .default) { [weak self] _ in
            let symbols = ["photo", "camera", "mountain.2", "sun.max", "leaf", "flame"]
            guard let symbol = symbols.randomElement() else { return }
            self?.senderChain.send(.symbol(symbol))
            self?.chatService.scheduleIncomingReply()
        })

        if let lastReceived = chatService.lastReceivedMessage {
            let preview = String((lastReceived.text ?? "(image)").prefix(30))
            sheet.addAction(UIAlertAction(title: "↩️ Reply to \"\(preview)\"", style: .default) { [weak self] _ in
                self?.senderChain.send(.reply(to: lastReceived, text: "Thanks for that!"))
                self?.chatService.scheduleIncomingReply()
            })
            sheet.addAction(UIAlertAction(title: "➡️ Forward \"\(preview)\"", style: .default) { [weak self] _ in
                self?.senderChain.send(.forward(lastReceived))
            })
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = bar
            popover.sourceRect = CGRect(x: 30, y: 0, width: 1, height: 1)
        }

        present(sheet, animated: true)
    }
}

// MARK: - UITextFieldDelegate (Emoji Keyboard)

extension SampleChatViewController: UITextFieldDelegate {

    /// Called every time the user types a character on the emoji keyboard.
    /// We grab the emoji, apply it as a reaction, and dismiss.
    /// Non-emoji characters (regular text if the user switches keyboards)
    /// are silently rejected.
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField === emojiTextField,
              !string.isEmpty,
              let target = quickReactionTarget else {
            return false
        }

        // Only accept actual emoji characters.
        guard string.unicodeScalars.allSatisfy({ $0.properties.isEmoji && $0.value > 0x23F }) else {
            return false
        }

        chatService.toggleReaction(emoji: string, on: target)
        textField.resignFirstResponder()
        quickReactionTarget = nil
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === emojiTextField else { return }
        quickReactionTarget = nil
    }
}

// MARK: - EmojiTextField

/// A UITextField that always presents the emoji keyboard.
///
/// It overrides `textInputMode` to return the emoji input mode and
/// hides the caret and selection handles so it looks invisible.
/// The globe button is hidden so the user cannot switch to a
/// non-emoji keyboard.
private final class EmojiTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Hide the globe / keyboard-switch button so the user stays
        // on the emoji keyboard. Available on iOS 17+.
        if #available(iOS 17.0, *) {
            // .never removes the globe button entirely.
            textInputTraits_setShouldShowGlobeKey(false)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }

    /// Prevent the caret from showing.
    override func caretRect(for position: UITextPosition) -> CGRect { .zero }

    /// Prevent selection handles from showing.
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { [] }

    // Try to hide the globe key through the private trait.
    // Falls back gracefully if the selector doesn't exist.
    private func textInputTraits_setShouldShowGlobeKey(_ show: Bool) {
        let selector = NSSelectorFromString("setAllowsKeyboardChanging:")
        if responds(to: selector) {
            perform(selector, with: show as NSNumber)
        }
    }
}
