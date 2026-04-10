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
    case update(items: [Item])
}
