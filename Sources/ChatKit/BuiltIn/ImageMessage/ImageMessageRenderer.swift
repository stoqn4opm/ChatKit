import UIKit

/// Renders real image messages (local files and remote URLs).
///
/// This renderer handles `.local` and `.remote` image sources.
/// SF Symbol images are handled by `SymbolMessageRenderer` instead.
public final class ImageMessageRenderer: MessageRenderer {

    private let errorRouter: ErrorRouting
    private let imageLoader: ImageLoading

    public init(errorRouter: ErrorRouting, imageLoader: ImageLoading) {
        self.errorRouter = errorRouter
        self.imageLoader = imageLoader
    }

    public func canRender(_ item: ChatItem) -> Bool {
        guard case .message(let msg) = item,
              let source = msg.imageSource else { return false }
        switch source {
        case .local, .remote:
            return msg.replyingTo == nil && msg.forwardedFrom == nil
        case .symbol:
            return false
        }
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(ImageBubbleCell.self,
                                forCellWithReuseIdentifier: ImageBubbleCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageBubbleCell.reuseID, for: indexPath
        ) as? ImageBubbleCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "ImageMessageRenderer",
                                   reuseIdentifier: ImageBubbleCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: ImageBubbleCell.reuseID, for: indexPath)
        }
        cell.imageLoader = imageLoader
        if case .message(let msg) = item {
            cell.configure(with: msg)
        }
        return cell
    }
}
