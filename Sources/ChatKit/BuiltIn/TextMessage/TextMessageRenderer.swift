import UIKit

/// Renders plain text messages (no reply, no forward, no image).
public final class TextMessageRenderer: MessageRenderer {
    private let errorRouter: ErrorRouting

    public init(errorRouter: ErrorRouting) {
        self.errorRouter = errorRouter
    }

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        return msg.text != nil
            && msg.imageSource == nil
            && msg.replyingTo == nil
            && msg.forwardedFrom == nil
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(TextBubbleCell.self,
                                forCellWithReuseIdentifier: TextBubbleCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TextBubbleCell.reuseID, for: indexPath
        ) as? TextBubbleCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "TextMessageRenderer",
                                   reuseIdentifier: TextBubbleCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: TextBubbleCell.reuseID, for: indexPath)
        }
        if case .message(let msg) = item {
            cell.configure(with: msg)
        }
        return cell
    }
}
