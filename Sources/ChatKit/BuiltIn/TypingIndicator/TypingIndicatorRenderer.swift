import UIKit

/// Renders the animated typing indicator (bouncing dots).
public final class TypingIndicatorRenderer: MessageRenderer {
    private let errorRouter: ErrorRouting
    private let showsAvatar: Bool

    public init(errorRouter: ErrorRouting, showsAvatar: Bool = true) {
        self.errorRouter = errorRouter
        self.showsAvatar = showsAvatar
    }

    public func canRender(_ item: ChatItem) -> Bool {
        if case .typingIndicator = item { return true }
        return false
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(TypingIndicatorCell.self,
                                forCellWithReuseIdentifier: TypingIndicatorCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TypingIndicatorCell.reuseID, for: indexPath
        ) as? TypingIndicatorCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "TypingIndicatorRenderer",
                                   reuseIdentifier: TypingIndicatorCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: TypingIndicatorCell.reuseID, for: indexPath)
        }
        cell.configure(name: "Alice", color: .systemPurple, showsAvatar: showsAvatar)
        return cell
    }
}
