import UIKit
import Combine
import ChatKit

final class SampleChatViewController: UIViewController {

    // MARK: - Dependencies

    private let chatService = MockChatService()
    private var chatView: ChatCollectionView<ChatItem>!
    private let inputBar = ChatInputBar()

    /// Builder-produced renderer chain.
    private var rendererChain: RendererChain!

    /// Builder-produced sender chain.
    private var senderChain: SenderChain!

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chat"
        navigationItem.largeTitleDisplayMode = .never

        let factory = ChatViewBuilder.standard()
        // To add a custom message type in your app:
        //   factory.prependRenderer(AudioMessageRenderer())
        //   factory.prependSender(AudioMessageSender())

        let built = factory.buildChatView()
        chatView = built.view
        rendererChain = built.renderers

        senderChain = factory.buildSenderChain(subject: chatService.updateSubject)

        setupChatView()
        setupInputBar()
        setupLayout()
        bindReactive()
        chatService.loadInitialMessages()
        chatService.startAmbientChat()
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
