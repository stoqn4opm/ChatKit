import UIKit

/// Composes an ordered list of `MessageRenderer`s into a single renderer.
///
/// `RendererChain` itself conforms to `MessageRenderer` — it iterates through
/// its children and delegates to the first one that can handle the item. This
/// keeps individual renderers decoupled: they never hold a `next` reference
/// and don't know they're part of a chain.
///
/// More specific renderers (reply, forwarded) should come first;
/// generic ones (text) should come last as fallbacks.
public final class RendererChain: MessageRenderer {

    private static let fallbackReuseID = "_ChatKit_Fallback"

    private let renderers: [MessageRenderer]
    private let errorRouter: ErrorRouting

    public init(renderers: [MessageRenderer], errorRouter: ErrorRouting) {
        precondition(!renderers.isEmpty, "RendererChain needs at least one renderer")
        self.renderers = renderers
        self.errorRouter = errorRouter
    }

    // MARK: - MessageRenderer

    /// Returns `true` if any child renderer can handle the item.
    public func canRender(_ item: ChatItem) -> Bool {
        renderers.contains { $0.canRender(item) }
    }

    /// Register every child renderer's cells with the collection view,
    /// plus an internal fallback cell used when no renderer matches.
    public func registerCells(in collectionView: UICollectionView) {
        for renderer in renderers {
            renderer.registerCells(in: collectionView)
        }
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: Self.fallbackReuseID
        )
    }

    /// Walk the children and return the first matching cell.
    ///
    /// If no renderer can handle the item, the error is routed through
    /// the injected `ErrorRouting` and a blank fallback cell is returned
    /// so the collection view never crashes.
    public func render(_ item: ChatItem,
                       in collectionView: UICollectionView,
                       at indexPath: IndexPath) -> UICollectionViewCell {
        for renderer in renderers where renderer.canRender(item) {
            return renderer.render(item, in: collectionView, at: indexPath)
        }
        errorRouter.route(.rendererNotFound(item: item))
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.fallbackReuseID, for: indexPath)
    }

    // MARK: - Convenience

    /// Alias for `registerCells(in:)`.
    public func registerAll(in collectionView: UICollectionView) {
        registerCells(in: collectionView)
    }

    /// Alias for `render(_:in:at:)`.
    public func cell(for item: ChatItem,
                     in collectionView: UICollectionView,
                     at indexPath: IndexPath) -> UICollectionViewCell {
        render(item, in: collectionView, at: indexPath)
    }
}
