import Foundation

/// Describes a non-fatal error encountered inside ChatKit.
///
/// ChatKit never crashes on its own — all errors are routed through
/// `ChatKitErrorRouter.shared` so the consuming app decides the policy
/// (log, assert, show UI, ignore, etc.).
public enum ChatKitError: CustomStringConvertible, Sendable {

    // MARK: - Rendering

    /// The renderer chain was walked to the end and no renderer
    /// returned `true` from `canRender(_:)` for this item.
    ///
    /// A fallback blank cell is displayed instead.
    /// Fix: register a renderer whose `canRender` matches this item type.
    case rendererNotFound(item: ChatItem)

    /// A renderer tried to dequeue a cell but the cast to the expected
    /// type failed. This usually means `registerCells(in:)` was not called
    /// or the reuse identifier is wrong.
    ///
    /// A fallback unconfigured cell is returned instead.
    case cellDequeueFailed(renderer: String, reuseIdentifier: String)

    // MARK: - Sending

    /// The sender chain was walked to the end and no sender
    /// returned `true` from `canSend(_:)` for this action.
    ///
    /// The action is silently dropped.
    /// Fix: register a sender whose `canSend` matches this action type.
    case senderNotFound(action: SendAction)

    // MARK: - Description

    public var description: String {
        switch self {
        case .rendererNotFound(let item):
            return "No renderer in the chain can render item: \(item). "
                 + "Register a renderer whose canRender(_:) returns true for this item."

        case .cellDequeueFailed(let renderer, let reuseID):
            return "Renderer '\(renderer)' failed to dequeue cell with identifier '\(reuseID)'. "
                 + "Ensure registerCells(in:) was called and the reuse identifier matches."

        case .senderNotFound(let action):
            return "No sender in the chain can handle action: \(action). "
                 + "Register a sender whose canSend(_:) returns true for this action."
        }
    }
}
