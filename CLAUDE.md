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

`ChatViewBuilder` (in `Sources/ChatKit/Builder/`) is the single place where all dependencies are assembled. It produces:
- `ChatCollectionView<ChatItem>` + `RendererChain` via `buildChatView()`
- `SenderChain` via `buildSenderChain(subject:)`

**No singletons.** All dependencies are constructor-injected. The builder exposes `errorRouter` and `imageLoader` so custom plugins can share them.

### Plugin System

Each message type is a `MessageTypePlugin` (protocol in `Sources/ChatKit/MessageTypePlugin.swift`). A plugin bundles:
- A `MessageRenderer` (the low-level cell provider — see below for body renderers)
- An optional `MessageSender` (knows how to turn a `SendAction` into a `ChatUpdate`)

Plugins are registered on the builder: `builder.register(MyPlugin(...))`. Unregister by metatype: `builder.unregister(TextMessagePlugin.self)`.

Registration order matters — renderers are checked first-to-last (chain of responsibility). Put specific types before generic ones.

### Unified Bubble Cell & Body Renderers

All message types (text, image, symbol, reply, forwarded) share a single cell class: **`MessageBubbleCell`** (in `Sources/ChatKit/Views/`). It provides the shared chrome — bubble background, avatar, timestamp, read receipts, and incoming/outgoing layout. The message-specific content is a **body view** returned by a `MessageBodyRenderer`.

**`MessageBodyRenderer`** (protocol in `Sources/ChatKit/Rendering/MessageBodyRenderer.swift`) replaces per-type cell rendering:
- `bodyReuseIdentifier` — unique ID per body type (e.g. `"Text"`, `"Reply"`)
- `createBodyView()` — creates the UIView once per cell instance
- `configureBody(_:with:isOutgoing:eventHandler:)` — reconfigures it for each message
- `prepareBodyForReuse(_:)` — cleans up on cell reuse

**`BodyRendererAdapter`** (in `Sources/ChatKit/Rendering/BodyRendererAdapter.swift`) wraps a `MessageBodyRenderer` into a `MessageRenderer` so it can participate in the `RendererChain`. Each built-in plugin creates this adapter internally — consumers never reference it directly.

**`MessageBodyEvent`** is an enum for events emitted by body views (e.g. `.quoteTapped(ChatMessage)` from reply bodies). The builder wires these to `ChatCollectionView`'s Combine publishers.

**`BubbleConfiguration`** (in `Sources/ChatKit/Views/BubbleConfiguration.swift`) controls avatar visibility (`.incomingOnly`, `.outgoingOnly`, `.both`, `.none`) and max bubble width fraction. Passed to `ChatViewBuilder.standard(bubbleConfig:)`.

Display-only types (DateSeparator, TypingIndicator) keep their own cells and use `MessageRenderer` directly — they don't go through the unified bubble.

### Renderer / Sender Chains

`RendererChain` iterates renderers until one returns `canRender(_:) == true`, then calls `render(_:in:at:)`. Body-renderer-based plugins participate through `BodyRendererAdapter`.

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

- Body views: `{Type}BodyView` (e.g. `TextBodyView`, `ReplyBodyView`) — internal, in each BuiltIn folder
- Renderers: `{Type}MessageRenderer` (now conform to `MessageBodyRenderer`, not `MessageRenderer`)
- Senders: `{Type}MessageSender`
- Plugins: `{Type}MessagePlugin`
- Protocols end in `-ing` or `-Providing` (e.g. `BubbleProviding`, `ImageLoading`, `ErrorRouting`)

### Variable Naming

**Always use descriptive names.** Never `let v = UIView()` — write `let containerView = UIView()`. This is enforced across the codebase.

### File Organization

Each built-in message type has its own folder under `Sources/ChatKit/BuiltIn/`:
```
BuiltIn/
├── TextMessage/        (TextBodyView, TextMessageRenderer, TextMessageSender, TextMessagePlugin)
├── ImageMessage/       (ImageBodyView, ImageMessageRenderer, ImageMessageSender, ImageMessagePlugin)
├── SymbolMessage/      (SymbolBodyView, SymbolMessageRenderer, SymbolMessageSender, SymbolMessagePlugin)
├── ReplyMessage/       (ReplyBodyView, ReplyMessageRenderer, ReplyMessageSender, ReplyMessagePlugin)
├── ForwardedMessage/   (ForwardedBodyView, ForwardedMessageRenderer, ForwardedMessageSender, ForwardedMessagePlugin)
├── DateSeparator/      (DateSeparatorCell, DateSeparatorRenderer, DateSeparatorPlugin)
└── TypingIndicator/    (TypingIndicatorCell, TypingIndicatorRenderer, TypingIndicatorPlugin)
```

The unified `MessageBubbleCell` (in `Sources/ChatKit/Views/`) handles all bubble chrome. Body views are internal to each message type folder.

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
2. Create `YourBodyView.swift` — a `UIView` subclass with the message-specific content
3. Create `YourMessageRenderer.swift` conforming to `MessageBodyRenderer`
4. Create `YourMessageSender.swift` conforming to `MessageSender` (optional)
5. Create `YourMessagePlugin.swift` conforming to `MessageTypePlugin` — wrap the body renderer in a `BodyRendererAdapter`
6. Register in `ChatViewBuilder.standard()` at the right priority position
7. Add the new `SendAction` case if needed
8. SPM auto-discovers the files — no pbxproj edits needed

For display-only types that don't use a bubble (like date separators), conform to `MessageRenderer` directly and provide your own `UICollectionViewCell`.

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
- **`ImageMessageRenderer` uses KVO** on `UIImageView.image` to dismiss the loading spinner. The `isObservingImage` flag on `ImageBodyView` tracks observer state to avoid double-remove crashes.
- **`DefaultImageLoader` uses `objc_setAssociatedObject`** to store the URLSessionDataTask on the UIImageView for cancel-on-reuse.
- **`prepareBodyForReuse` must clean up** `onQuoteTapped` closures and `quotedMessage` references to prevent stale callbacks in recycled body views (see `ReplyBodyView.reset()`).
- **Body events flow through `BodyRendererAdapter.onBodyEvent`** → `ChatCollectionView.publishQuoteTapped(_:)`. The builder wires this during `buildChatView()`. Don't call `publishQuoteTapped` from consumer code.
- **`MessageBubbleCell` pre-creates 4 constraint sets** for all combinations of (outgoing/incoming) × (avatar visible/hidden). Deactivating all 4 before activating the right one avoids conflicting constraints.
- **Body renderers that need NSObject** (e.g. `ImageMessageRenderer` for KVO) must inherit from `NSObject` in addition to conforming to `MessageBodyRenderer`.
