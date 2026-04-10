# CLAUDE.md — AI Assistant Guide for ChatKit

This file gives AI coding assistants (Claude, Copilot, Cursor, etc.) the context needed to work effectively with this codebase. Treat it as the authoritative source on project conventions.

## What is ChatKit?

ChatKit is a reusable UIKit chat UI framework distributed as a Swift Package. It provides a `UICollectionView`-based chat interface with pagination, Combine-driven reactive data flow, a plugin system for custom message types, and a builder-pattern composition root. It targets iOS 15+ and has zero third-party dependencies.

## Project Layout

```
Sources/ChatKit/              # All framework code lives here
Tests/ChatKitTests/           # Unit tests
Examples/ChatKitDemo/         # Sample iOS app using the local package
ChatKit.xcworkspace           # Opens package + example together
Package.swift                 # SPM manifest (iOS 15+, Swift 5.9+)
```

## Build & Run

Open `ChatKit.xcworkspace` in Xcode. The workspace contains the Swift package (auto-discovered from the root `Package.swift`) and the example project (`Examples/ChatKitDemo/ChatKitDemo.xcodeproj`).

To build the package in isolation: `swift build` from the repo root.

To run the example app: select the `ChatKitDemo` scheme in the workspace and run on an iOS 15+ simulator.

To run tests: `swift test` or use the `ChatKitTests` target in Xcode.

The example app uses a local Swift package reference (`../../` relative to its xcodeproj). When you add files to `Sources/ChatKit/`, they are automatically included in the build — no need to touch the xcodeproj.

## Architecture — Core Abstractions

### Data Flow

All data flows through `ChatUpdate<Item>`, a Combine-driven enum:

```
Service → PassthroughSubject<ChatUpdate<ChatItem>> → ChatCollectionView.bind(to:)
```

Cases: `.initial`, `.append`, `.prepend`, `.remove`, `.update`.

The `ChatCollectionView<Item>` is fully generic. `ChatItem` is the concrete enum used by the built-in system (`.message(ChatMessage)`, `.dateSeparator(...)`, `.typingIndicator(...)`).

### Composition Root: ChatViewBuilder

`ChatViewBuilder` (in `Sources/ChatKit/Factory/`) is the single place where all dependencies are assembled. It produces:
- `ChatCollectionView<ChatItem>` + `RendererChain` via `buildChatView()`
- `SenderChain` via `buildSenderChain(subject:)`

**No singletons.** All dependencies are constructor-injected. The builder exposes `errorRouter` and `imageLoader` so custom plugins can share them.

### Plugin System

Each message type is a `MessageTypePlugin` (protocol in `Sources/ChatKit/MessageTypePlugin.swift`). A plugin bundles:
- A `MessageRenderer` (knows how to dequeue and configure a cell)
- An optional `MessageSender` (knows how to turn a `SendAction` into a `ChatUpdate`)

Plugins are registered on the builder: `builder.register(MyPlugin(...))`. Unregister by metatype: `builder.unregister(TextMessagePlugin.self)`.

Registration order matters — renderers are checked first-to-last (chain of responsibility). Put specific types before generic ones.

### Renderer / Sender Chains

`RendererChain` iterates renderers until one returns `canRender(_:) == true`, then calls `render(_:in:at:)`.

`SenderChain` iterates senders until one returns `canSend(_:) == true`, then calls `send(_:subject:)`.

Both log through `ChatKitErrorRouter` if no handler matches.

### Image Loading

Two protocols in `Sources/ChatKit/ImageLoading/`:
- `ImageLoading` — `loadImage(from:into:)` and `cancelLoad(for:)`. Injected into `ImageMessageRenderer`.
- `ImageCaching` — `cachedImage(for:)`, `store(_:for:)`, etc. Used by `DefaultImageLoader`.

`DefaultImageLoader` uses URLSession + NSCache. To swap in Kingfisher/Nuke/SDWebImage, conform to `ImageLoading` and pass it to `ChatViewBuilder(imageLoader:)`.

`ImageSource` enum: `.symbol(String)` for SF Symbols, `.local(URL)` for on-disk files, `.remote(URL)` for network images.

## Conventions & Patterns

### Naming

- Cells: `{Type}BubbleCell` (e.g. `TextBubbleCell`, `ReplyBubbleCell`)
- Renderers: `{Type}MessageRenderer`
- Senders: `{Type}MessageSender`
- Plugins: `{Type}MessagePlugin`
- Protocols end in `-ing` or `-Providing` (e.g. `BubbleProviding`, `ImageLoading`, `ErrorRouting`)

### Variable Naming

**Always use descriptive names.** Never `let v = UIView()` — write `let containerView = UIView()`. This is enforced across the codebase.

### File Organization

Each built-in message type has its own folder under `Sources/ChatKit/BuiltIn/`:
```
BuiltIn/
├── TextMessage/        (TextBubbleCell, TextMessageRenderer, TextMessageSender, TextMessagePlugin)
├── ImageMessage/       (ImageBubbleCell, ImageMessageRenderer, ImageMessageSender, ImageMessagePlugin)
├── SymbolMessage/      (SymbolBubbleCell, SymbolMessageRenderer, SymbolMessageSender, SymbolMessagePlugin)
├── ReplyMessage/       (ReplyBubbleCell, ReplyMessageRenderer, ReplyMessageSender, ReplyMessagePlugin)
├── ForwardedMessage/   (ForwardedBubbleCell, ForwardedMessageRenderer, ForwardedMessageSender, ForwardedMessagePlugin)
├── DateSeparator/      (DateSeparatorCell, DateSeparatorRenderer, DateSeparatorPlugin)
└── TypingIndicator/    (TypingIndicatorCell, TypingIndicatorRenderer, TypingIndicatorPlugin)
```

### Access Control

- Public API: `public` on types, initializers, and methods consumers need
- Internal wiring: `internal` (default) for things like `ReplyMessageRenderer.onQuoteTapped` which the builder sets
- Cell implementation details: `private`

### Error Handling

All components receive an `ErrorRouting` protocol (implemented by `ChatKitErrorRouter`). In DEBUG, errors trigger `assertionFailure`. In RELEASE, they're silently ignored unless a custom handler is set via `builder.onError { ... }`.

### Reactive Outputs

`ChatCollectionView` exposes these Combine publishers:
- `paginationRequested: AnyPublisher<Item?, Never>`
- `itemSelected: AnyPublisher<Item, Never>`
- `quoteTapped: AnyPublisher<ChatMessage, Never>`
- `itemBecameVisible / itemBecameHidden: AnyPublisher<Item, Never>`
- `isAtBottomChanged: AnyPublisher<Bool, Never>`
- `unreadCountChanged: AnyPublisher<Int, Never>`

### BubbleProviding Protocol

Cells that display a message bubble conform to `BubbleProviding` (returns `contextMenuTargetView`). This is used for:
- Hit-testing taps to the bubble area only (not the whole cell)
- Context menu targeting
- Scroll-to-message highlight animation (targets the bubble, not the cell)

### Scroll-to-Message

`ChatCollectionView.scrollToItem(_:animated:highlight:)` supports:
- Immediate scroll if the item is loaded
- Deferred scroll with automatic pagination if the item is in older pages
- Yellow flash highlight on the bubble after scrolling

The deferred scroll stores a target and triggers pagination. `attemptDeferredScroll()` is called at the end of `prependItems()`'s completion handler.

## Common Tasks

### Adding a New Built-in Message Type

1. Create a folder under `Sources/ChatKit/BuiltIn/YourType/`
2. Create `YourBubbleCell.swift` conforming to `BubbleProviding`
3. Create `YourMessageRenderer.swift` conforming to `MessageRenderer`
4. Create `YourMessageSender.swift` conforming to `MessageSender` (optional)
5. Create `YourMessagePlugin.swift` conforming to `MessageTypePlugin`
6. Register in `ChatViewBuilder.standard()` at the right priority position
7. Add the new `SendAction` case if needed
8. SPM auto-discovers the files — no pbxproj edits needed

### Modifying the Example App

The example app at `Examples/ChatKitDemo/` imports ChatKit as a local SPM dependency. Only 5 source files are compiled: `AppDelegate`, `SceneDelegate`, `SampleChatViewController`, `MockChatService`, `ChatInputBar`.

### Running Tests

```bash
swift test
# or in Xcode: Cmd+U on the ChatKitTests target
```

## Things to Watch Out For

- **Plugin registration order matters.** ReplyMessagePlugin must come before TextMessagePlugin, otherwise reply messages render as plain text.
- **`ChatMessage` is a value type** with a reference-typed `QuotedMessage` wrapper to avoid recursive structs.
- **`ImageBubbleCell` uses KVO** on `UIImageView.image` to dismiss the loading spinner. An `isObservingImage` flag tracks observer state to avoid double-remove crashes.
- **`DefaultImageLoader` uses `objc_setAssociatedObject`** to store the URLSessionDataTask on the UIImageView for cancel-on-reuse.
- **`prepareForReuse()` must clean up** `onQuoteTapped` closures and `quotedMessage` references to prevent stale callbacks in recycled cells.
- **The `publishQuoteTapped(_:)` method** on ChatCollectionView is internal — it bridges the renderer's cell callback to the public Combine publisher. Don't call it from consumer code.
