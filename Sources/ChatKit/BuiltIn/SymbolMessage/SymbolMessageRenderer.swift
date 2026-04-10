import UIKit

/// Renders symbol messages (SF Symbol bubbles, no reply, no forward).
public final class SymbolMessageRenderer: MessageRenderer {
    private let errorRouter: ErrorRouting

    public init(errorRouter: ErrorRouting) {
        self.errorRouter = errorRouter
    }

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item else { return false }
        if case .symbol = msg.imageSource { } else { return false }
        return msg.replyingTo == nil && msg.forwardedFrom == nil
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(SymbolBubbleCell.self,
                                forCellWithReuseIdentifier: SymbolBubbleCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SymbolBubbleCell.reuseID, for: indexPath
        ) as? SymbolBubbleCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "SymbolMessageRenderer",
                                   reuseIdentifier: SymbolBubbleCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: SymbolBubbleCell.reuseID, for: indexPath)
        }
        if case .message(let msg) = item {
            cell.configure(with: msg)
        }
        return cell
    }
}
