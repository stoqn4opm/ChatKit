import UIKit

/// Renders forwarded messages (bubble with "Forwarded from X" header).
public final class ForwardedMessageRenderer: MessageRenderer {
    private let errorRouter: ErrorRouting

    public init(errorRouter: ErrorRouting) {
        self.errorRouter = errorRouter
    }

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        return msg.forwardedFrom != nil
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(ForwardedBubbleCell.self,
                                forCellWithReuseIdentifier: ForwardedBubbleCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ForwardedBubbleCell.reuseID, for: indexPath
        ) as? ForwardedBubbleCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "ForwardedMessageRenderer",
                                   reuseIdentifier: ForwardedBubbleCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: ForwardedBubbleCell.reuseID, for: indexPath)
        }
        if case .message(let msg) = item {
            cell.configure(with: msg)
        }
        return cell
    }
}
