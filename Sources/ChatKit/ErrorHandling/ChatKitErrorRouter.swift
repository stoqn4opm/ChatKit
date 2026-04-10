import Foundation

/// The narrow interface that ChatKit components depend on for error reporting.
///
/// Classes like `RendererChain`, `SenderChain`, and the built-in renderers
/// receive this via their initializer — they never reach for a singleton.
/// This makes them testable and keeps the dependency graph explicit.
public protocol ErrorRouting {
    /// Report a non-fatal error. The implementation decides whether to log,
    /// crash, show UI, or ignore.
    func route(_ error: ChatKitError)
}

/// The default `ErrorRouting` implementation used by ChatKit.
///
/// In DEBUG builds, errors trigger `assertionFailure` (pauses in the
/// debugger). In RELEASE builds, errors are silently ignored.
/// Override `handler` to install your own policy.
///
/// You never access this directly from ChatKit internals — it is created
/// at the composition root (`ChatViewBuilder`) and injected into every
/// component that needs it.
///
/// ## Usage (via ChatViewBuilder)
///
/// ```swift
/// let builder = ChatViewBuilder.standard()
///     .onError { error in
///         Logger.chatKit.error("\(error.description)")
///     }
/// ```
public final class ChatKitErrorRouter: ErrorRouting {

    /// The closure invoked whenever a ChatKit component encounters an error.
    ///
    /// **Default behaviour:**
    /// - Debug builds: triggers `assertionFailure` (pauses in the debugger).
    /// - Release builds: no-op (the error is silently ignored).
    ///
    /// Set this to your own closure to log, alert, or escalate errors.
    public var handler: (ChatKitError) -> Void

    public init() {
        handler = { error in
            #if DEBUG
            assertionFailure("[ChatKit] \(error.description)")
            #endif
        }
    }

    // MARK: - ErrorRouting

    public func route(_ error: ChatKitError) {
        handler(error)
    }
}
