import Foundation
import Combine

/// A protocol that any chat data source must conform to.
/// The single `updates` publisher is the only channel through which
/// the view layer receives data — all mutations flow reactively.
public protocol ChatServiceProtocol: AnyObject {
    associatedtype Item: Hashable & Sendable

    /// A publisher that emits every mutation to the item list.
    /// Subscribers (typically `ChatCollectionView`) apply each update
    /// as it arrives. Must deliver on the **main queue**.
    var updates: AnyPublisher<ChatUpdate<Item>, Never> { get }

    /// Request the initial page of messages.
    func loadInitialMessages()

    /// Request the next older page (pagination).
    func loadOlderMessages()
}
