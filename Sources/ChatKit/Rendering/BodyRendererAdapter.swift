import UIKit

/// Wraps a `MessageBodyRenderer` into a `MessageRenderer` so it can
/// participate in the existing `RendererChain`.
///
/// The adapter dequeues a `MessageBubbleCell`, installs the body view on
/// first use, and delegates body configuration to the wrapped renderer.
/// Chrome (avatar, timestamp, reactions, colours) is configured by the
/// cell itself.
///
/// This class is an internal implementation detail — consumers work with
/// `MessageBodyRenderer` and `MessageTypePlugin` and never reference this
/// class directly.
final class BodyRendererAdapter: MessageRenderer {

    /// The wrapped body renderer.
    let bodyRenderer: MessageBodyRenderer

    /// Bubble configuration driving avatar visibility and max width.
    let bubbleConfig: BubbleConfiguration

    /// Reaction configuration driving inline pill display.
    var reactionConfig: ReactionConfiguration = .default

    /// Cell reuse identifier — unique per body type.
    private let reuseIdentifier: String

    /// Called when a body view emits an event (e.g. quote tap).
    /// Wired by `ChatViewBuilder` after the renderer chain is built.
    var onBodyEvent: ((MessageBodyEvent) -> Void)?

    /// Called when the user taps an existing reaction pill.
    /// Parameters: (message, emoji). Wired by the builder.
    var onReactionTapped: ((ChatMessage, String) -> Void)?

    /// Called when the user taps the "+" add-reaction button.
    /// Parameter: message. Wired by the builder.
    var onAddReactionTapped: ((ChatMessage) -> Void)?

    init(bodyRenderer: MessageBodyRenderer, bubbleConfig: BubbleConfiguration) {
        self.bodyRenderer = bodyRenderer
        self.bubbleConfig = bubbleConfig
        self.reuseIdentifier = "MessageBubbleCell_\(bodyRenderer.bodyReuseIdentifier)"
    }

    // MARK: - MessageRenderer

    func canRender(_ item: ChatItem) -> Bool {
        bodyRenderer.canRender(item)
    }

    func registerCells(in collectionView: UICollectionView) {
        collectionView.register(
            MessageBubbleCell.self,
            forCellWithReuseIdentifier: reuseIdentifier)
    }

    func render(_ item: ChatItem,
                in collectionView: UICollectionView,
                at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier, for: indexPath
        ) as? MessageBubbleCell else {
            // Should never happen since we register the correct class,
            // but return *something* so the collection view doesn't crash.
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseIdentifier, for: indexPath)
        }

        // Install the body view on the first dequeue of this cell instance.
        if cell.bodyView == nil {
            let bodyView = bodyRenderer.createBodyView()
            cell.installBodyView(bodyView)
        }

        guard case .message(let message) = item else { return cell }

        // Wire reaction callbacks BEFORE configure() so that
        // ReactionPillsView captures live closures, not nil.
        let reactionHandler = onReactionTapped
        let addHandler = onAddReactionTapped
        cell.onReactionTapped = { emoji in reactionHandler?(message, emoji) }
        cell.onAddReactionTapped = { addHandler?(message) }

        // Configure shared chrome (avatar, meta, reactions)
        cell.configure(with: message,
                       avatarVisibility: bubbleConfig.avatarVisibility,
                       reactionConfig: reactionConfig)

        // Configure body content
        let eventHandler = onBodyEvent
        bodyRenderer.configureBody(
            cell.bodyView!,
            with: message,
            isOutgoing: message.sender.isMe,
            eventHandler: eventHandler)

        // Wire prepareForReuse cleanup
        let bodyView = cell.bodyView
        let renderer = bodyRenderer
        cell.onPrepareBodyForReuse = {
            guard let bodyView = bodyView else { return }
            renderer.prepareBodyForReuse(bodyView)
        }

        return cell
    }
}
