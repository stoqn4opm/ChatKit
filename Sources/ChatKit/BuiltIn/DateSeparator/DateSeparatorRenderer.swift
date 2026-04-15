import UIKit

/// Renders date separator pills between message groups.
public final class DateSeparatorRenderer: MessageRenderer {
    private let errorRouter: ErrorRouting
    private let textColor: UIColor?
    private let pillColor: UIColor?

    public init(errorRouter: ErrorRouting, textColor: UIColor? = nil, pillColor: UIColor? = nil) {
        self.errorRouter = errorRouter
        self.textColor = textColor
        self.pillColor = pillColor
    }

    public func canRender(_ item: ChatItem) -> Bool {
        if case .dateSeparator = item { return true }
        return false
    }

    public func registerCells(in collectionView: UICollectionView) {
        collectionView.register(DateSeparatorCell.self,
                                forCellWithReuseIdentifier: DateSeparatorCell.reuseID)
    }

    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DateSeparatorCell.reuseID, for: indexPath
        ) as? DateSeparatorCell else {
            errorRouter.route(
                .cellDequeueFailed(renderer: "DateSeparatorRenderer",
                                   reuseIdentifier: DateSeparatorCell.reuseID))
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: DateSeparatorCell.reuseID, for: indexPath)
        }
        if case .dateSeparator(_, let text) = item {
            cell.configure(text: text, textColor: textColor, pillColor: pillColor)
        }
        return cell
    }
}
