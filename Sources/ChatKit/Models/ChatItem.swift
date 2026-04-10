import Foundation

/// The top-level item type used with `ChatCollectionView<ChatItem>`.
/// Each case maps to a different cell type in the cell provider.
public enum ChatItem: Hashable, Sendable {
    case message(ChatMessage)
    case dateSeparator(id: UUID = UUID(), text: String)
    case typingIndicator(id: UUID = UUID())

    /// Returns the underlying ChatMessage if this is a `.message` case.
    public var asMessage: ChatMessage? {
        if case .message(let msg) = self { return msg }
        return nil
    }
}
