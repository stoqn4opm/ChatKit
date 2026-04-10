import UIKit

/// Describes how to display a single message type in a collection view.
///
/// Each message type implements this protocol. The `RendererChain` iterates
/// through renderers in priority order; the first one whose `canRender(_:)`
/// returns `true` provides the cell.
///
/// Renderers are simple, standalone strategy objects — they know nothing
/// about chains or ordering. The chain-walking logic lives in `RendererChain`.
///
/// To add a new message type, create a class conforming to `MessageRenderer`
/// and register it via `ChatViewBuilder.register(_:)`.
public protocol MessageRenderer: AnyObject {

    /// Returns `true` if this renderer knows how to display the given item.
    func canRender(_ item: ChatItem) -> Bool

    /// Register any cell classes this renderer needs with the collection view.
    func registerCells(in collectionView: UICollectionView)

    /// Dequeue and configure a cell for the given item.
    /// Only called when `canRender` has already returned `true`.
    func render(_ item: ChatItem,
                in collectionView: UICollectionView,
                at indexPath: IndexPath) -> UICollectionViewCell
}
