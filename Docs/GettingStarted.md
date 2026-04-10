# Getting Started with ChatKit

This guide walks you through integrating ChatKit into an iOS app, from zero to a working chat screen with pagination, replies, and message sending.

## Prerequisites

- Xcode 15+
- iOS 15+ deployment target
- A UIKit-based project (ChatKit uses `UICollectionView` under the hood)

## Step 1: Add the Dependency

In Xcode, go to File > Add Package Dependencies and enter the ChatKit repository URL. Select the `ChatKit` library product and add it to your app target.

Or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/ChatKit.git", from: "1.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["ChatKit"])
]
```

## Step 2: Create a Chat View Controller

```swift
import UIKit
import Combine
import ChatKit

final class ChatViewController: UIViewController {

    private var chatView: ChatCollectionView<ChatItem>!
    private var senderChain: SenderChain!
    private var cancellables = Set<AnyCancellable>()

    // Your backend service — must expose a PassthroughSubject<ChatUpdate<ChatItem>, Never>
    private let chatService: MyChatService

    init(chatService: MyChatService) {
        self.chatService = chatService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Build everything via the builder
        let builder = ChatViewBuilder.standard()
        let (view, renderers) = builder.buildChatView()
        chatView = view
        senderChain = builder.buildSenderChain(subject: chatService.updateSubject)

        // 2. Add to view hierarchy
        chatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatView)
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 3. Bind to data
        chatView.bind(to: chatService.updates)

        // 4. Subscribe to events
        chatView.paginationRequested
            .sink { [weak self] _ in self?.chatService.loadOlderMessages() }
            .store(in: &cancellables)

        chatView.quoteTapped
            .sink { [weak self] originalMessage in
                self?.chatView.scrollToItem(.message(originalMessage))
            }
            .store(in: &cancellables)

        // 5. Load initial data
        chatService.loadInitialMessages()
    }
}
```

## Step 3: Implement Your Chat Service

ChatKit doesn't dictate your backend. It consumes `ChatUpdate<ChatItem>` values through a Combine publisher. Your service just needs to emit them:

```swift
final class MyChatService {
    let updateSubject = PassthroughSubject<ChatUpdate<ChatItem>, Never>()

    var updates: AnyPublisher<ChatUpdate<ChatItem>, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func loadInitialMessages() {
        // Fetch from your API, then:
        let items: [ChatItem] = messages.map { .message($0) }
        updateSubject.send(.initial(items: items, hasMorePages: true))
    }

    func loadOlderMessages() {
        // Fetch older page, then:
        let olderItems: [ChatItem] = olderMessages.map { .message($0) }
        updateSubject.send(.prepend(items: olderItems, hasMorePages: hasMore))
    }
}
```

The five `ChatUpdate` cases:

| Case | When to Use |
|------|-------------|
| `.initial(items:hasMorePages:)` | First page load. Replaces everything and scrolls to bottom. |
| `.append(items:scrollToBottom:)` | New messages arrive. Auto-scrolls if user is at bottom. |
| `.prepend(items:hasMorePages:)` | Older messages loaded. Preserves scroll position. |
| `.remove(items:)` | Message deleted/unsent. |
| `.update(items:)` | Message edited or status changed. Reconfigures cells in place. |

## Step 4: Send Messages

Use the `SenderChain` built by the builder:

```swift
// Plain text
senderChain.send(.text("Hello!"))

// SF Symbol
senderChain.send(.symbol("heart.fill"))

// Image from URL
senderChain.send(.image(.remote(imageURL)))

// Reply
senderChain.send(.reply(to: originalMessage, text: "Great point!"))

// Forward
senderChain.send(.forward(someMessage))
```

The sender chain publishes the appropriate `ChatUpdate` to your service's subject automatically.

## Step 5: Context Menus

Add long-press context menus on message bubbles:

```swift
chatView.setContextMenuProvider { item in
    guard case .message(let message) = item else { return nil }
    return UIMenu(children: [
        UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
            // Handle reply
        },
        UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
            UIPasteboard.general.string = message.text
        },
    ])
}
```

Context menus are automatically scoped to the bubble — long-pressing the avatar or empty space won't trigger them.

## Customization

### Custom Scroll-to-Bottom Button

```swift
let builder = ChatViewBuilder.standard()
    .scrollToBottom(ScrollToBottomConfiguration(
        position: ScrollToBottomPosition(alignment: .center, bottomInset: 20),
        viewFactory: { MyCustomScrollButton() }
    ))
```

Pass `nil` to disable the button entirely.

### Custom Error Handling

```swift
let builder = ChatViewBuilder.standard()
    .onError { error in
        Logger.chatKit.error("\(error.description)")
    }
```

### Custom Image Loader

Swap in Kingfisher, Nuke, or SDWebImage by conforming to `ImageLoading`:

```swift
final class KingfisherImageLoader: ImageLoading {
    func loadImage(from source: ImageSource, into imageView: UIImageView) {
        guard case .remote(let url) = source else { return }
        imageView.kf.setImage(with: url)
    }

    func cancelLoad(for imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}

let builder = ChatViewBuilder(imageLoader: KingfisherImageLoader())
```

### Custom Message Types

See the **Extending with Custom Message Types** section in the README, or study any of the built-in plugins under `Sources/ChatKit/BuiltIn/` — each one is a self-contained example.

## Reactive Subscribers Reference

```swift
// Mark messages as read when they scroll into view
chatView.itemBecameVisible
    .compactMap { $0.asMessage }
    .filter { !$0.sender.isMe && !$0.isRead }
    .sink { message in api.markAsRead(message.id) }
    .store(in: &cancellables)

// Show/hide a tab bar badge
chatView.unreadCountChanged
    .sink { count in tabBarItem.badgeValue = count > 0 ? "\(count)" : nil }
    .store(in: &cancellables)

// Tap a quoted message block to scroll to the original
chatView.quoteTapped
    .sink { [weak chatView] original in
        chatView?.scrollToItem(.message(original))
    }
    .store(in: &cancellables)
```

## Next Steps

- Explore the example app in `Examples/ChatKitDemo/` for a full working implementation
- Read `CLAUDE.md` for architecture details and codebase conventions
- Check the source documentation in individual files for API-level details
