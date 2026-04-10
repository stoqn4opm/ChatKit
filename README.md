# ChatKit

A reusable, content-agnostic UIKit chat component for iOS. ChatKit provides a production-ready `UICollectionView`-based chat interface with pagination, read receipts, emoji reactions, context menus, scroll-to-message, and a plugin system for custom message types — all driven by Combine and built on `NSDiffableDataSourceSnapshot`.

## Features

- **UICollectionView + CompositionalLayout** with automatic cell sizing
- **DiffableDataSource** for smooth, animated data updates
- **Pagination** — scroll near the top to load older messages with preserved scroll position
- **Scroll-to-message** — programmatic scrolling with deferred pagination support and highlight flash
- **Emoji reactions** — tap to toggle, quick-reaction bar, full emoji keyboard, configurable or fully disableable
- **Combine publishers** for every lifecycle event (visibility, selection, pagination, unread count, quote taps, reactions)
- **Context menus** scoped to the message bubble (not the full cell)
- **Scroll-to-bottom button** with unread badge, fully customizable
- **Plugin system** — register/unregister message types with a single call
- **Builder pattern** (`ChatViewBuilder`) as the composition root — no singletons, full constructor injection
- **Image loading** with protocol-based caching (`ImageCaching`) and loading (`ImageLoading`) abstractions
- **Built-in message types:** text, image (local/remote), SF Symbol, reply (with quote-tap navigation), forwarded, date separator, typing indicator

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add ChatKit to your project via SPM. In Xcode: File > Add Package Dependencies, then enter the repository URL.

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/ChatKit.git", from: "1.0.0")
]
```

Then add `"ChatKit"` as a dependency of your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["ChatKit"]
)
```

### Local Development

Clone the repo and open `ChatKit.xcworkspace`. The workspace contains the Swift package and the example app side by side.

```bash
git clone https://github.com/your-org/ChatKit.git
cd ChatKit
open ChatKit.xcworkspace
```

## Quick Start

```swift
import ChatKit

// 1. Create a builder with all built-in message types
let builder = ChatViewBuilder.standard()

// 2. Build the chat view (renderers are wired internally)
let chatView = builder.buildChatView()

// 3. Build the sender chain (needs your service's update subject)
let senderChain = builder.buildSenderChain(subject: chatService.updateSubject)

// 4. Bind to your data stream
chatView.bind(to: chatService.updates)

// 5. Send a message
senderChain.send(.text("Hello, world!"))
```

See [`Docs/GettingStarted.md`](Docs/GettingStarted.md) for a full walkthrough, or explore the example app in `Examples/ChatKitDemo/`.

## Architecture

ChatKit is built around a few core concepts:

**ChatCollectionView&lt;Item&gt;** is the main UI component. It's a generic, content-agnostic view that knows nothing about message rendering. You provide a cell-provider closure (or use the builder), and it handles layout, scrolling, pagination, and all the reactive plumbing.

**ChatViewBuilder** is the composition root. It assembles renderers, senders, error routing, bubble configuration, and the chat view itself. All dependencies flow through constructors — no global state.

**MessageBubbleCell** is the unified bubble cell. All message types share this single cell class, which provides the chrome (avatar, timestamp, bubble background, reaction pills, alignment). Message-specific content is a **body view** created by a `MessageBodyRenderer` and embedded in the bubble.

**MessageBodyRenderer** defines how a message type renders its content as a plain `UIView`. The `BodyRendererAdapter` wraps it into the `MessageRenderer` interface so it plugs into the existing chain.

**MessageTypePlugin** bundles a renderer and an optional sender for a single message type. Register plugins with the builder; unregister by metatype (`builder.unregister(TextMessagePlugin.self)`).

**RendererChain / SenderChain** are chain-of-responsibility dispatchers. The first renderer that `canRender` an item wins. The first sender that `canSend` an action wins.

**BubbleConfiguration** controls avatar visibility (incoming-only, outgoing-only, both, none) and max bubble width. Pass it to `ChatViewBuilder.standard(bubbleConfig:)`.

**ReactionConfiguration** controls the emoji reaction system — enable/disable toggle, max visible pills, quick-reaction emoji set, and add-button visibility. Pass it to `ChatViewBuilder.standard(reactionConfig:)` or use `.disabled` to turn reactions off entirely.

**ChatUpdate&lt;Item&gt;** is the reactive data contract — an enum with cases for `.initial`, `.append`, `.prepend`, `.remove`, and `.update`.

## Repository Structure

```
ChatKit/
├── Package.swift
├── Sources/ChatKit/          # The framework
│   ├── Models/               # ChatMessage, ChatItem, ImageSource, Reaction
│   ├── Rendering/            # MessageRenderer, MessageBodyRenderer, RendererChain, BodyRendererAdapter
│   ├── Sending/              # MessageSender protocol, SenderChain
│   ├── BuiltIn/              # Built-in plugins (Text, Image, Symbol, Reply, Forwarded, DateSeparator, TypingIndicator)
│   ├── ImageLoading/         # ImageLoading/ImageCaching protocols + defaults
│   ├── Builder/              # ChatViewBuilder (composition root)
│   ├── ErrorHandling/        # ChatKitError, ChatKitErrorRouter
│   ├── Views/                # MessageBubbleCell, BubbleConfiguration, ReactionPillsView, QuickReactionBar, AvatarView, ScrollToBottomView
│   └── Utilities/            # ReadReceiptScheduler
├── Tests/ChatKitTests/       # Unit tests
├── Examples/ChatKitDemo/     # Example iOS app
│   ├── ChatKitDemo.xcodeproj
│   └── SampleApp/
├── Docs/
│   └── GettingStarted.md
├── ChatKit.xcworkspace       # Opens package + example together
├── CLAUDE.md                 # AI assistant guide
└── README.md
```

## Extending with Custom Message Types

Create a body renderer, body view, and plugin:

```swift
// 1. Body view (UIView subclass with your content)
final class AudioBodyView: UIView { /* waveform, play button, etc. */ }

// 2. Body renderer
final class AudioBodyRenderer: MessageBodyRenderer {
    var bodyReuseIdentifier: String { "Audio" }
    func canRender(_ item: ChatItem) -> Bool { /* ... */ }
    func createBodyView() -> UIView { AudioBodyView() }
    func configureBody(_ bodyView: UIView, with message: ChatMessage,
                       isOutgoing: Bool, eventHandler: ((MessageBodyEvent) -> Void)?) { /* ... */ }
    func prepareBodyForReuse(_ bodyView: UIView) { /* ... */ }
}

// 3. Plugin (wraps body renderer in BodyRendererAdapter)
struct AudioMessagePlugin: MessageTypePlugin {
    let renderer: MessageRenderer
    let sender: MessageSender?

    init(bubbleConfig: BubbleConfiguration = .default) {
        renderer = BodyRendererAdapter(
            bodyRenderer: AudioBodyRenderer(), bubbleConfig: bubbleConfig)
        sender = AudioMessageSender()
    }
}
```

Register it:

```swift
let builder = ChatViewBuilder.standard()
builder.register(AudioMessagePlugin(bubbleConfig: builder.bubbleConfig))
```

Or replace a built-in type:

```swift
builder
    .unregister(TextMessagePlugin.self)
    .register(RichTextMessagePlugin(bubbleConfig: builder.bubbleConfig))
```

## Emoji Reactions

Reactions are enabled by default. Toggle or customize them via `ReactionConfiguration`:

```swift
// Default: reactions enabled with 👍 ❤️ 😂 😮 😢 🙏 quick bar
let builder = ChatViewBuilder.standard()

// Disable reactions entirely
let builder = ChatViewBuilder.standard(reactionConfig: .disabled)

// Customize
let builder = ChatViewBuilder.standard(
    reactionConfig: ReactionConfiguration(
        isEnabled: true,
        maxVisibleReactions: 5,
        quickReactions: ["👍", "❤️", "🔥", "🎉"],
        showAddButton: true
    )
)
```

Subscribe to reaction events:

```swift
chatView.reactionTapped
    .sink { message, emoji in
        service.toggleReaction(emoji: emoji, on: message)
    }
    .store(in: &cancellables)

chatView.addReactionTapped
    .sink { message in
        showQuickReactionBar(for: message)
    }
    .store(in: &cancellables)
```

Update reactions on a message by publishing a `.update` with the modified `ChatMessage`:

```swift
let updated = message.addingReaction(Reaction(emoji: "👍", sender: .me))
updateSubject.send(.update(items: [.message(updated)]))
```

## License

MIT
