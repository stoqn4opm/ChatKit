import UIKit

/// Renders reply messages (bubble with quoted original above the reply text).
public final class ReplyMessageRenderer: MessageRenderer {
    private let errorRouter: ErrorRouting

    /// Injected by the builder after constructing the chat view.
    /// Fires when the user taps the quoted-message block.
    var onQuoteTapped: ((ChatMessage) -> Void)?

    public init(errorRouter: ErrorRouting) {
        self.errorRouter = errorRouter
    }

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        return msg.replyingTo != nil
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(ReplyBubbleCell.self,
                                forCellWithReuseIdentifier: ReplyBubbleCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ReplyBubbleCell.reuseID, for: indexPath
        ) as? ReplyBubbleCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "ReplyMessageRenderer",
                                   reuseIdentifier: ReplyBubbleCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: ReplyBubbleCell.reuseID, for: indexPath)
        }
        if case .message(let msg) = item {
            cell.onQuoteTapped = onQuoteTapped
            cell.configure(with: msg)
        }
        return cell
    }
}
