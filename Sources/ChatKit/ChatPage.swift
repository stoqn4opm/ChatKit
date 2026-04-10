import Foundation

/// A page of chat items returned from a data source.
/// Items must be ordered oldest → newest.
public struct ChatPage<Item: Hashable & Sendable> {
    /// The items in this page, ordered oldest first.
    public let items: [Item]
    /// Whether there are more (older) pages available beyond this one.
    public let hasNextPage: Bool

    public init(items: [Item], hasNextPage: Bool) {
        self.items = items
        self.hasNextPage = hasNextPage
    }
}
