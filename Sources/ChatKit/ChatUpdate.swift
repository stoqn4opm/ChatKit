import Foundation
import Combine

/// Describes a mutation to the chat item list.
/// Published by a data source; consumed by `ChatCollectionView` via `bind(to:)`.
public enum ChatUpdate<Item: Hashable & Sendable> {
    /// Replace the entire list (initial load or full refresh).
    case initial(items: [Item], hasMorePages: Bool)

    /// Append new items at the bottom (new incoming/outgoing messages).
    case append(items: [Item], scrollToBottom: Bool)

    /// Prepend older items at the top (pagination). Preserves scroll position.
    case prepend(items: [Item], hasMorePages: Bool)

    /// Remove specific items (unsend, hide typing indicator).
    case remove(items: [Item])

    /// Update items in-place (read receipts, delivery status, edit).
    /// The items must already exist in the list (matched by identity/hash).
    /// Triggers `reconfigureItems` on iOS 15+ so the cell provider re-runs.
    /// The cell class must stay the same — UIKit's `reconfigureItems`
    /// requires the same reuse identifier as the existing cell.
    case update(items: [Item])

    /// Replaces items with a fresh dequeue (cell class may change).
    /// The items must already exist in the list (matched by identity/hash).
    /// Triggers `reloadItems` on the diffable data source so the cell
    /// provider dequeues a new cell. Use this when the item's renderer
    /// (cell class) needs to change — e.g. a text message being unsent
    /// and rendering as an unsent-placeholder cell.
    case reload(items: [Item])
}
