import UIKit
import Combine

/// The composition root for ChatKit.
///
/// Creates, configures, and wires together every ChatKit component —
/// renderers, senders, error routing, and the chat view itself. All
/// dependencies are injected via initializers; no singletons are
/// accessed inside ChatKit internals.
///
/// ## Usage
///
/// ```swift
/// // Use all defaults:
/// let builder = ChatViewBuilder.standard()
///
/// // Custom bubble configuration:
/// let builder = ChatViewBuilder.standard(
///     bubbleConfig: BubbleConfiguration(avatarVisibility: .both)
/// )
///
/// // Extend with a custom type — one call registers everything:
/// builder.register(AudioMessagePlugin(bubbleConfig: builder.bubbleConfig))
///
/// // Build:
/// let chatView = builder.buildChatView()
/// let senderChain = builder.buildSenderChain(subject: service.updateSubject)
/// ```
public final class ChatViewBuilder {

    private var renderers: [MessageRenderer] = []
    private var senders: [MessageSender] = []
    private var pluginEntries: [(type: Any.Type, renderer: MessageRenderer, sender: MessageSender?)] = []
    private var scrollToBottomConfig: ScrollToBottomConfiguration? = .default

    /// The error router that all ChatKit components share.
    /// Exposed so custom plugins can use the same instance.
    public let errorRouter: ChatKitErrorRouter

    /// The image loader that all image-related components share.
    /// Exposed so custom plugins can use the same instance.
    public let imageLoader: ImageLoading

    /// The bubble configuration used by body-renderer-based plugins.
    /// Exposed so custom plugins can match the built-in appearance.
    public let bubbleConfig: BubbleConfiguration

    /// The reaction configuration controlling inline pill display,
    /// quick-reaction emojis, and visibility thresholds.
    /// Exposed so custom plugins can match the built-in behaviour.
    public let reactionConfig: ReactionConfiguration

    public init(errorRouter: ChatKitErrorRouter = ChatKitErrorRouter(),
                imageLoader: ImageLoading = DefaultImageLoader(),
                bubbleConfig: BubbleConfiguration = .default,
                reactionConfig: ReactionConfiguration = .default) {
        self.errorRouter = errorRouter
        self.imageLoader = imageLoader
        self.bubbleConfig = bubbleConfig
        self.reactionConfig = reactionConfig
    }

    // MARK: - Standard Builder

    /// Creates a builder pre-loaded with all built-in message types.
    ///
    /// Plugin registration order (most specific → most generic):
    /// 1. ReplyMessagePlugin
    /// 2. ForwardedMessagePlugin
    /// 3. ImageMessagePlugin        (real images — local/remote)
    /// 4. SymbolMessagePlugin       (SF Symbol glyphs)
    /// 5. TextMessagePlugin
    /// 6. DateSeparatorPlugin       (display-only, no sender)
    /// 7. TypingIndicatorPlugin     (display-only, no sender)
    public static func standard(
        bubbleConfig: BubbleConfiguration = .default,
        reactionConfig: ReactionConfiguration = .default
    ) -> ChatViewBuilder {
        let builder = ChatViewBuilder(bubbleConfig: bubbleConfig,
                                      reactionConfig: reactionConfig)
        let loader = builder.imageLoader
        let config = builder.bubbleConfig
        let router = builder.errorRouter

        // Most specific first — generic last
        builder.register(ReplyMessagePlugin(bubbleConfig: config))
        builder.register(ForwardedMessagePlugin(bubbleConfig: config))
        builder.register(ImageMessagePlugin(imageLoader: loader, bubbleConfig: config))
        builder.register(SymbolMessagePlugin(bubbleConfig: config))
        builder.register(TextMessagePlugin(bubbleConfig: config))
        builder.register(DateSeparatorPlugin(errorRouter: router))
        builder.register(TypingIndicatorPlugin(errorRouter: router))
        return builder
    }

    // MARK: - Plugin Registration

    /// Registers a message type plugin, appending its renderer and sender
    /// to the end of their respective chains (lowest priority).
    ///
    /// This is the primary way to extend ChatKit with new message types.
    /// Each plugin bundles a renderer and optionally a sender — one call
    /// wires up everything the message type needs.
    @discardableResult
    public func register(_ plugin: MessageTypePlugin) -> Self {
        renderers.append(plugin.renderer)
        if let sender = plugin.sender {
            senders.append(sender)
        }
        pluginEntries.append((type: type(of: plugin), renderer: plugin.renderer, sender: plugin.sender))
        return self
    }

    /// Registers a message type plugin at the front of the chains
    /// (highest priority). Use this for custom types that should be
    /// checked before all built-in types.
    @discardableResult
    public func registerFirst(_ plugin: MessageTypePlugin) -> Self {
        renderers.insert(plugin.renderer, at: 0)
        if let sender = plugin.sender {
            senders.insert(sender, at: 0)
        }
        pluginEntries.append((type: type(of: plugin), renderer: plugin.renderer, sender: plugin.sender))
        return self
    }

    /// Removes all renderers and senders that were registered via the
    /// given plugin type.
    ///
    /// Useful for replacing a built-in message type with a custom one:
    /// ```swift
    /// builder
    ///     .unregister(TextMessagePlugin.self)
    ///     .register(MyCustomTextMessagePlugin(bubbleConfig: builder.bubbleConfig))
    /// ```
    @discardableResult
    public func unregister<P: MessageTypePlugin>(_ pluginType: P.Type) -> Self {
        let matching = pluginEntries.filter { $0.type == pluginType }
        for entry in matching {
            renderers.removeAll { $0 === entry.renderer }
            if let sender = entry.sender {
                senders.removeAll { $0 === sender }
            }
        }
        pluginEntries.removeAll { $0.type == pluginType }
        return self
    }

    // MARK: - Fine-Grained Registration

    /// Appends a renderer to the end of the chain (lowest priority / fallback).
    /// Prefer `register(_:)` for most cases.
    @discardableResult
    public func addRenderer(_ renderer: MessageRenderer) -> Self {
        renderers.append(renderer)
        return self
    }

    /// Inserts a renderer at the beginning of the chain (highest priority).
    /// Prefer `registerFirst(_:)` for most cases.
    @discardableResult
    public func prependRenderer(_ renderer: MessageRenderer) -> Self {
        renderers.insert(renderer, at: 0)
        return self
    }

    /// Removes all renderers whose type matches the given class.
    @discardableResult
    public func removeRenderer(ofType type: MessageRenderer.Type) -> Self {
        renderers.removeAll { Swift.type(of: $0) == type }
        return self
    }

    /// Appends a sender to the end of the chain (lowest priority / fallback).
    /// Prefer `register(_:)` for most cases.
    @discardableResult
    public func addSender(_ sender: MessageSender) -> Self {
        senders.append(sender)
        return self
    }

    /// Inserts a sender at the beginning of the chain (highest priority).
    /// Prefer `registerFirst(_:)` for most cases.
    @discardableResult
    public func prependSender(_ sender: MessageSender) -> Self {
        senders.insert(sender, at: 0)
        return self
    }

    /// Removes all senders whose type matches the given class.
    @discardableResult
    public func removeSender(ofType type: MessageSender.Type) -> Self {
        senders.removeAll { Swift.type(of: $0) == type }
        return self
    }

    // MARK: - Scroll-to-Bottom Button

    /// Customizes the scroll-to-bottom button's appearance and position.
    ///
    /// ```swift
    /// // Custom look at bottom-center:
    /// let builder = ChatViewBuilder.standard()
    ///     .scrollToBottom(ScrollToBottomConfiguration(
    ///         position: ScrollToBottomPosition(alignment: .center),
    ///         viewFactory: { MyFancyScrollButton() }
    ///     ))
    ///
    /// // Disable the button entirely:
    /// let builder = ChatViewBuilder.standard()
    ///     .scrollToBottom(nil)
    /// ```
    @discardableResult
    public func scrollToBottom(_ config: ScrollToBottomConfiguration?) -> Self {
        scrollToBottomConfig = config
        return self
    }

    // MARK: - Error Handling

    /// Sets a custom error handler for all ChatKit errors.
    ///
    /// By default ChatKit triggers `assertionFailure` in DEBUG builds and
    /// silently ignores errors in RELEASE. Use this to install your own
    /// policy — e.g. logging to Crashlytics, showing a toast, or crashing
    /// hard during QA builds.
    ///
    /// ```swift
    /// let builder = ChatViewBuilder.standard()
    ///     .onError { error in
    ///         Logger.chatKit.error("\(error.description)")
    ///     }
    /// ```
    @discardableResult
    public func onError(_ handler: @escaping (ChatKitError) -> Void) -> Self {
        errorRouter.handler = handler
        return self
    }

    // MARK: - Build

    /// Builds a `SenderChain` from the currently registered senders.
    public func buildSenderChain(subject: PassthroughSubject<ChatUpdate<ChatItem>, Never>) -> SenderChain {
        SenderChain(senders: senders, subject: subject, errorRouter: errorRouter)
    }

    /// Builds a fully wired `ChatCollectionView` with the renderer chain
    /// already set as the cell provider and all event publishers connected.
    ///
    /// The renderer chain is created, registered, and captured internally —
    /// consumers don't need direct access to it.
    public func buildChatView() -> ChatCollectionView<ChatItem> {
        let chain = RendererChain(renderers: renderers, errorRouter: errorRouter)
        let chatView = ChatCollectionView<ChatItem>(
            scrollToBottomConfig: scrollToBottomConfig
        ) { collectionView, indexPath, item in
            chain.cell(for: item, in: collectionView, at: indexPath)
        }
        chain.registerAll(in: chatView.collectionView)

        // Wire body events and reactions from BodyRendererAdapters → chatView publishers
        let rxConfig = reactionConfig
        for renderer in renderers {
            if let adapter = renderer as? BodyRendererAdapter {
                adapter.reactionConfig = rxConfig

                adapter.onBodyEvent = { [weak chatView] event in
                    switch event {
                    case .quoteTapped(let originalMessage):
                        chatView?.publishQuoteTapped(originalMessage)
                    }
                }

                if rxConfig.isEnabled {
                    adapter.onReactionTapped = { [weak chatView] message, emoji in
                        chatView?.publishReactionTapped(message: message, emoji: emoji)
                    }

                    adapter.onAddReactionTapped = { [weak chatView] message in
                        chatView?.publishAddReactionTapped(message: message)
                    }
                }
            }
        }

        return chatView
    }
}
