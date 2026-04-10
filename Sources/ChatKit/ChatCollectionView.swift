import UIKit
import Combine

/// Cells that conform to this protocol tell the collection view which subview
/// represents the "bubble" so that context menus only trigger on the bubble area.
public protocol BubbleProviding: UICollectionViewCell {
    /// The bubble subview that should be the target for context menu interactions.
    var contextMenuTargetView: UIView { get }
}

/// A reusable, content-agnostic chat-style collection view.
///
/// `Item` is the type the consumer uses to represent rows (messages, date separators,
/// typing indicators, etc.). The component knows nothing about rendering — the consumer
/// provides a `CellProvider` closure that dequeues and configures cells.
///
/// ## Data Flow
///
/// **Reactive (preferred):** call `bind(to:)` with an `AnyPublisher<ChatUpdate<Item>, Never>`.
/// The view subscribes and applies every update automatically.
///
/// **Imperative (legacy):** call `replaceAllItems`, `appendItems`, `prependItems`,
/// `removeItems`, `updateItems` directly. These are also used internally by the
/// reactive binding.
///
/// ## Lifecycle Hooks (Combine Publishers)
///
/// ChatKit exposes every meaningful event as a Combine publisher so the
/// consuming app can react without subclassing or injecting delegates:
///
/// | Publisher              | Fires when…                                        | Typical use                    |
/// |------------------------|----------------------------------------------------|--------------------------------|
/// | `itemBecameVisible`    | A cell scrolls into the visible area               | Mark-as-read API call          |
/// | `itemBecameHidden`     | A cell scrolls out of the visible area              | Pause video/audio playback     |
/// | `isAtBottomChanged`    | The user scrolls to/from the newest messages        | Show/hide external UI badges   |
/// | `unreadCountChanged`   | The off-screen unread count increments or resets    | Update tab bar badge           |
/// | `paginationRequested`  | The user scrolls near the top                       | Load older messages            |
/// | `itemSelected`         | The user taps an item                               | Navigate, show detail          |
///
/// ## Scrolling
/// - Newest items at the bottom; oldest at the top.
/// - Appending auto-scrolls **only** when the user is already near the bottom
///   or when the update explicitly requests it (e.g. the current user just sent a message).
/// - When the user has scrolled up to read older messages a floating "scroll to bottom"
///   button appears with an unread-message count. New messages never yank the scroll
///   position away from the user.
/// - The button's appearance and position are customizable via
///   `ScrollToBottomConfiguration`.
/// - Prepending preserves the current scroll position.
/// - Scrolling near the top publishes on `paginationRequested`.
///
/// ## Context Menu
/// - Long-pressing a bubble shows a popover with actions from the `ContextMenuProvider`.
public final class ChatCollectionView<Item: Hashable & Sendable>: UIView,
    UICollectionViewDelegate, UIScrollViewDelegate {

    // MARK: - Types

    public typealias CellProvider = (UICollectionView, IndexPath, Item) -> UICollectionViewCell?
    public typealias ContextMenuProvider = (Item) -> UIMenu?

    private enum Section: Hashable { case main }

    // MARK: - Public Configuration

    /// Distance from the bottom (in points) within which the user is considered "at the bottom".
    public var nearBottomThreshold: CGFloat = 60

    /// Distance from the top (in points) at which pagination is triggered.
    public var paginationTriggerOffset: CGFloat = 300

    // MARK: - Reactive Outputs — Navigation

    /// Fires when the user scrolls near the top and more pages are available.
    /// The service should respond by publishing a `.prepend` update.
    public var paginationRequested: AnyPublisher<Item?, Never> {
        _paginationSubject.eraseToAnyPublisher()
    }
    private let _paginationSubject = PassthroughSubject<Item?, Never>()

    /// Fires when the user taps an item.
    public var itemSelected: AnyPublisher<Item, Never> {
        _selectionSubject.eraseToAnyPublisher()
    }
    private let _selectionSubject = PassthroughSubject<Item, Never>()

    /// Fires when the user taps the quoted-message block inside a reply bubble.
    /// The emitted `ChatMessage` is the **original** message being replied to,
    /// so the consumer can scroll to it or navigate to the originating chat.
    public var quoteTapped: AnyPublisher<ChatMessage, Never> {
        _quoteTappedSubject.eraseToAnyPublisher()
    }
    private let _quoteTappedSubject = PassthroughSubject<ChatMessage, Never>()

    // MARK: - Reactive Outputs — Visibility

    /// Fires when an item's cell scrolls **into** the visible area.
    ///
    /// This is the hook for read receipts — subscribe and fire your
    /// "mark as read" API call whenever the item is a message from
    /// another user:
    ///
    /// ```swift
    /// chatView.itemBecameVisible
    ///     .compactMap { $0.asMessage }
    ///     .filter { !$0.sender.isMe && !$0.isRead }
    ///     .sink { message in
    ///         api.markAsRead(message.id)
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    public var itemBecameVisible: AnyPublisher<Item, Never> {
        _visibleSubject.eraseToAnyPublisher()
    }
    private let _visibleSubject = PassthroughSubject<Item, Never>()

    /// Fires when an item's cell scrolls **out of** the visible area.
    ///
    /// Useful for pausing media playback (video, audio, GIFs) when the
    /// cell is no longer on screen.
    public var itemBecameHidden: AnyPublisher<Item, Never> {
        _hiddenSubject.eraseToAnyPublisher()
    }
    private let _hiddenSubject = PassthroughSubject<Item, Never>()

    // MARK: - Reactive Outputs — Scroll State

    /// Fires when the user's scroll position **transitions** to or from
    /// the bottom of the chat. Only fires on actual changes — not on
    /// every scroll tick.
    ///
    /// `true` means the user just arrived at the newest messages;
    /// `false` means the user just scrolled away.
    public var isAtBottomChanged: AnyPublisher<Bool, Never> {
        _isAtBottomSubject.eraseToAnyPublisher()
    }
    private let _isAtBottomSubject = PassthroughSubject<Bool, Never>()

    /// Fires whenever the off-screen unread count changes.
    ///
    /// Resets to `0` when the user scrolls back to the bottom or taps
    /// the scroll-to-bottom button. Increments when new items arrive
    /// while the user is scrolled away. Use it to drive an external
    /// badge (e.g. on a tab bar).
    public var unreadCountChanged: AnyPublisher<Int, Never> {
        _unreadCountSubject.eraseToAnyPublisher()
    }
    private let _unreadCountSubject = PassthroughSubject<Int, Never>()

    // MARK: - Closures (kept for convenience alongside reactive outputs)

    private var _contextMenuProvider: ContextMenuProvider?

    /// Sets the context menu provider. Return a `UIMenu` with the desired actions,
    /// or `nil` to disable the context menu for that item.
    public func setContextMenuProvider(_ provider: @escaping ContextMenuProvider) {
        _contextMenuProvider = provider
    }

    /// Called by renderers (via the builder) when a quote block is tapped.
    /// Routes the event into the `quoteTapped` publisher.
    func publishQuoteTapped(_ originalMessage: ChatMessage) {
        _quoteTappedSubject.send(originalMessage)
    }

    // MARK: - Internal State

    private var hasMorePages: Bool = true
    private var isLoadingOlderMessages: Bool = false
    private var currentItems: [Item] = []
    private var cancellables = Set<AnyCancellable>()

    /// When set, the view will try to scroll to this item after every data update.
    /// Cleared once the item is found and scrolled to.
    private var deferredScrollTarget: Item?

    /// Tracks whether the user is currently at (or very close to) the bottom.
    /// Updated on every scroll event.
    private var userIsAtBottom: Bool = true

    /// Counts new messages that arrived while the user was scrolled away.
    private var unreadWhileAway: Int = 0 {
        didSet {
            guard unreadWhileAway != oldValue else { return }
            _unreadCountSubject.send(unreadWhileAway)
        }
    }

    // MARK: - Subviews

    public private(set) var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let topSpinner = UIActivityIndicatorView(style: .medium)

    /// The scroll-to-bottom button, created from the configuration's factory.
    private var scrollToBottomButton: (any ScrollToBottomProviding)?

    // MARK: - Init

    /// Creates a chat collection view with a cell provider and an optional
    /// scroll-to-bottom configuration.
    ///
    /// - Parameters:
    ///   - scrollToBottomConfig: Controls the appearance and position of the
    ///     floating "scroll to bottom" button. Pass `.default` (or omit) for
    ///     the built-in pill at bottom-trailing. Pass `nil` to disable the
    ///     button entirely.
    ///   - cellProvider: Dequeues and configures cells for each item.
    public init(
        scrollToBottomConfig: ScrollToBottomConfiguration? = .default,
        cellProvider: @escaping CellProvider
    ) {
        super.init(frame: .zero)
        setupCollectionView(cellProvider: cellProvider)
        setupTopSpinner()
        if let config = scrollToBottomConfig {
            setupScrollToBottomButton(config: config)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Reactive Binding

    /// Subscribes to a stream of `ChatUpdate` values and applies each one.
    /// This is the primary way to drive the view reactively.
    /// The publisher must deliver on the **main queue**.
    public func bind(to publisher: AnyPublisher<ChatUpdate<Item>, Never>) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.apply(update)
            }
            .store(in: &cancellables)
    }

    private func apply(_ update: ChatUpdate<Item>) {
        switch update {
        case .initial(let items, let hasMorePages):
            replaceAllItems(items, hasMorePages: hasMorePages)

        case .append(let items, let scrollToBottom):
            appendItems(items, animated: true, forceScrollToBottom: scrollToBottom)

        case .prepend(let items, let hasMorePages):
            prependItems(items, hasMorePages: hasMorePages)

        case .remove(let items):
            removeItems(items, animated: true)

        case .update(let items):
            updateItems(items)
        }
    }

    // MARK: - Setup

    private func setupCollectionView(cellProvider: @escaping CellProvider) {
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            cellProvider(collectionView, indexPath, item)
        }
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.showsSeparators = false
        config.backgroundColor = .clear
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func setupTopSpinner() {
        topSpinner.translatesAutoresizingMaskIntoConstraints = false
        topSpinner.hidesWhenStopped = true
        addSubview(topSpinner)

        NSLayoutConstraint.activate([
            topSpinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            topSpinner.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])
    }

    private func setupScrollToBottomButton(config: ScrollToBottomConfiguration) {
        let button = config.viewFactory()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        addSubview(button)

        // Bottom constraint — always present
        button.bottomAnchor.constraint(
            equalTo: bottomAnchor,
            constant: -config.position.bottomInset
        ).isActive = true

        // Horizontal constraint — varies by alignment
        switch config.position.alignment {
        case .leading:
            button.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: config.position.sideInset
            ).isActive = true

        case .center:
            button.centerXAnchor.constraint(
                equalTo: centerXAnchor
            ).isActive = true

        case .trailing:
            button.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -config.position.sideInset
            ).isActive = true
        }

        button.onTap = { [weak self] in
            guard let self else { return }
            self.unreadWhileAway = 0
            self.scrollToBottomButton?.unreadCount = 0
            self.scrollToBottom(animated: true)
        }

        scrollToBottomButton = button
    }

    // MARK: - Scroll-to-Bottom Button Visibility

    private func updateScrollToBottomVisibility() {
        guard let button = scrollToBottomButton else { return }

        let shouldShow = !userIsAtBottom
        let targetAlpha: CGFloat = shouldShow ? 1 : 0

        guard button.alpha != targetAlpha else { return }

        UIView.animate(withDuration: 0.25) {
            button.alpha = targetAlpha
        }

        // User scrolled back to the bottom — clear unread
        if !shouldShow {
            unreadWhileAway = 0
            button.unreadCount = 0
        }
    }

    // MARK: - Public API (Imperative)

    /// The underlying collection view, exposed for cell registration.
    public var underlyingCollectionView: UICollectionView {
        collectionView
    }

    /// Returns the item at the given index, if valid.
    public func item(at index: Int) -> Item? {
        guard index >= 0, index < currentItems.count else { return nil }
        return currentItems[index]
    }

    /// Replaces all items and scrolls to the bottom.
    public func replaceAllItems(_ items: [Item], hasMorePages: Bool, scrollToBottom: Bool = true) {
        self.currentItems = items
        self.hasMorePages = hasMorePages
        self.isLoadingOlderMessages = false
        self.topSpinner.stopAnimating()

        // Full reload — reset unread state
        self.unreadWhileAway = 0
        self.scrollToBottomButton?.unreadCount = 0

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            if scrollToBottom {
                self?.scrollToBottom(animated: false)
            }
        }
    }

    /// Appends new items to the bottom.
    ///
    /// - `forceScrollToBottom = true`: always scrolls (use for current-user sends).
    /// - `forceScrollToBottom = false`: scrolls only if the user is already at the
    ///   bottom. Otherwise increments the unread badge on the scroll-to-bottom button.
    public func appendItems(_ items: [Item], animated: Bool = true, forceScrollToBottom: Bool = false) {
        let shouldAutoScroll = forceScrollToBottom || userIsAtBottom
        currentItems.append(contentsOf: items)

        var snapshot = dataSource.snapshot()
        if snapshot.numberOfSections == 0 {
            snapshot.appendSections([.main])
        }
        snapshot.appendItems(items, toSection: .main)

        if !shouldAutoScroll {
            // User is reading older messages — count these as unread
            unreadWhileAway += items.count
            scrollToBottomButton?.unreadCount = unreadWhileAway
        }

        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            if shouldAutoScroll {
                self?.scrollToBottom(animated: animated)
            }
        }
    }

    /// Prepends older items, preserving scroll position.
    public func prependItems(_ items: [Item], hasMorePages: Bool) {
        guard !items.isEmpty else {
            self.hasMorePages = hasMorePages
            isLoadingOlderMessages = false
            topSpinner.stopAnimating()
            return
        }

        self.hasMorePages = hasMorePages
        currentItems.insert(contentsOf: items, at: 0)

        let oldContentHeight = collectionView.contentSize.height
        let oldOffset = collectionView.contentOffset.y

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(currentItems, toSection: .main)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            guard let self else { return }
            self.collectionView.layoutIfNeeded()

            let newContentHeight = self.collectionView.contentSize.height
            let delta = newContentHeight - oldContentHeight
            self.collectionView.contentOffset.y = oldOffset + delta

            CATransaction.commit()

            self.isLoadingOlderMessages = false
            self.topSpinner.stopAnimating()

            self.attemptDeferredScroll()
        }
    }

    /// Removes specific items.
    public func removeItems(_ items: [Item], animated: Bool = true) {
        currentItems.removeAll { items.contains($0) }

        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(items)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    /// Updates existing items in-place by reconfiguring their cells.
    /// Items are matched by identity (Hashable). The cell provider re-runs
    /// for each updated item, so any changed properties are reflected.
    public func updateItems(_ items: [Item]) {
        // Update the local cache
        let updatedSet = Set(items)
        for (index, existing) in currentItems.enumerated() {
            if let replacement = updatedSet.first(where: { $0 == existing }) {
                currentItems[index] = replacement
            }
        }

        var snapshot = dataSource.snapshot()
        // reconfigureItems is iOS 15+ — re-invokes the cell provider without
        // deleting/inserting, so it's smooth and preserves cell state.
        let validItems = items.filter { snapshot.itemIdentifiers.contains($0) }
        guard !validItems.isEmpty else { return }
        snapshot.reconfigureItems(validItems)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    /// Scrolls to the very bottom.
    public func scrollToBottom(animated: Bool) {
        guard !currentItems.isEmpty else { return }
        let lastIndex = IndexPath(item: currentItems.count - 1, section: 0)
        collectionView.scrollToItem(at: lastIndex, at: .bottom, animated: animated)
    }

    // MARK: - Scroll to Item

    /// Scrolls to a specific item if it's currently loaded, with an optional
    /// highlight flash on the target cell.
    ///
    /// If the item is not yet in the data source (e.g. it's in an older page
    /// that hasn't been fetched), the request is stored as a **deferred scroll
    /// target**. The view will automatically trigger pagination and attempt
    /// the scroll after each prepend until the item is found.
    ///
    /// This is the building block for "tap a reply → jump to the original
    /// message" and for cross-chat "open chat and scroll to message" flows.
    ///
    /// - Parameters:
    ///   - item: The item to scroll to.
    ///   - animated: Whether to animate the scroll.
    ///   - highlight: Whether to briefly flash the target cell after scrolling.
    public func scrollToItem(_ item: Item, animated: Bool = true, highlight: Bool = true) {
        if let index = currentItems.firstIndex(of: item) {
            deferredScrollTarget = nil
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)

            if highlight {
                // Delay slightly so the scroll completes before flashing
                let delay: TimeInterval = animated ? 0.35 : 0.05
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.highlightCell(at: indexPath)
                }
            }
        } else if hasMorePages {
            // Item not loaded yet — store as deferred target and trigger pagination
            deferredScrollTarget = item
            if !isLoadingOlderMessages {
                isLoadingOlderMessages = true
                topSpinner.startAnimating()
                _paginationSubject.send(currentItems.first)
            }
        }
    }

    /// Checks whether the deferred scroll target is now present after a data
    /// update. Called internally after prepend operations.
    private func attemptDeferredScroll() {
        guard let target = deferredScrollTarget else { return }

        if let index = currentItems.firstIndex(of: target) {
            deferredScrollTarget = nil
            let indexPath = IndexPath(item: index, section: 0)

            // Use layoutIfNeeded so the collection view knows about the new cells
            collectionView.layoutIfNeeded()
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.highlightCell(at: indexPath)
            }
        } else if hasMorePages && !isLoadingOlderMessages {
            // Still not found — keep loading older pages
            isLoadingOlderMessages = true
            topSpinner.startAnimating()
            _paginationSubject.send(currentItems.first)
        } else if !hasMorePages {
            // No more pages and item not found — give up
            deferredScrollTarget = nil
        }
    }

    /// Briefly flashes the bubble to draw the user's attention to the scrolled-to message.
    /// If the cell conforms to `BubbleProviding`, the highlight targets the bubble;
    /// otherwise it falls back to the full cell.
    private func highlightCell(at indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }

        let targetView: UIView
        if let bubbleCell = cell as? BubbleProviding {
            targetView = bubbleCell.contextMenuTargetView
        } else {
            targetView = cell
        }

        let highlightView = UIView(frame: targetView.bounds)
        highlightView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3)
        highlightView.layer.cornerRadius = targetView.layer.cornerRadius
        highlightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        targetView.addSubview(highlightView)

        UIView.animate(withDuration: 0.8, delay: 0.4, options: .curveEaseOut) {
            highlightView.alpha = 0
        } completion: { _ in
            highlightView.removeFromSuperview()
        }
    }

    /// Whether the user's scroll position is near the bottom.
    public var isNearBottom: Bool {
        let offsetY = collectionView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let frameHeight = collectionView.frame.height
        let insetBottom = collectionView.adjustedContentInset.bottom
        return offsetY >= contentHeight - frameHeight - insetBottom - nearBottomThreshold
    }

    // MARK: - UIScrollViewDelegate — Pagination + Bottom Tracking

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let wasAtBottom = userIsAtBottom
        userIsAtBottom = isNearBottom

        // Only publish when the value actually transitions
        if userIsAtBottom != wasAtBottom {
            _isAtBottomSubject.send(userIsAtBottom)
        }

        updateScrollToBottomVisibility()

        // Pagination
        guard hasMorePages,
              !isLoadingOlderMessages,
              scrollView.contentOffset.y < paginationTriggerOffset,
              !currentItems.isEmpty else { return }

        isLoadingOlderMessages = true
        topSpinner.startAnimating()

        _paginationSubject.send(currentItems.first)
    }

    // MARK: - UICollectionViewDelegate — Selection

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.item < currentItems.count else { return }

        // If the cell provides a bubble view, only fire the selection
        // when the tap landed inside the bubble — not on the avatar,
        // meta label, or empty padding around it.
        if let cell = collectionView.cellForItem(at: indexPath),
           let bubbleCell = cell as? BubbleProviding {
            let tapPoint = collectionView.panGestureRecognizer.location(in: cell)
            let bubbleFrame = bubbleCell.contextMenuTargetView.frame
            guard bubbleFrame.contains(tapPoint) else { return }
        }

        _selectionSubject.send(currentItems[indexPath.item])
    }

    // MARK: - UICollectionViewDelegate — Visibility

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard indexPath.item < currentItems.count else { return }
        _visibleSubject.send(currentItems[indexPath.item])
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        // After a snapshot apply the index may be stale — guard against it.
        guard indexPath.item < currentItems.count else { return }
        _hiddenSubject.send(currentItems[indexPath.item])
    }

    // MARK: - Context Menu

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard indexPath.item < currentItems.count,
              let provider = _contextMenuProvider else { return nil }

        if let cell = collectionView.cellForItem(at: indexPath) as? BubbleProviding {
            let bubbleView = cell.contextMenuTargetView
            let pointInBubble = collectionView.convert(point, to: bubbleView)
            guard bubbleView.bounds.contains(pointInBubble) else { return nil }
        }

        let item = currentItems[indexPath.item]
        guard let menu = provider(item) else { return nil }

        return UIContextMenuConfiguration(identifier: indexPath as NSCopying,
                                          previewProvider: nil) { _ in menu }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetedPreview(for: configuration)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetedPreview(for: configuration)
    }

    private func targetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: indexPath) as? BubbleProviding else {
            return nil
        }
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.visiblePath = UIBezierPath(
            roundedRect: cell.contextMenuTargetView.bounds,
            cornerRadius: 16
        )
        return UITargetedPreview(view: cell.contextMenuTargetView, parameters: params)
    }
}
