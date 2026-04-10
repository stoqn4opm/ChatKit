import Foundation
import Combine
import ChatKit

/// A mock chat data source that publishes all mutations through a Combine pipeline.
/// Conforms to `ChatServiceProtocol` so it can be swapped for a real backend.
///
/// Send logic has been extracted into `MessageSender` implementations
/// composed via `SenderChain`. This service is responsible for:
/// - Loading initial / older pages (pagination)
/// - Ambient chat simulation (random incoming messages)
/// - Providing the shared subject that senders publish to
/// - Unsend (remove)
final class MockChatService: ChatServiceProtocol {

    // MARK: - ChatServiceProtocol

    var updates: AnyPublisher<ChatUpdate<ChatItem>, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    /// The shared subject that both this service and `SenderChain` publish to.
    let updateSubject = PassthroughSubject<ChatUpdate<ChatItem>, Never>()

    // MARK: - Private

    private let pageSize = 20
    private let totalMessages = 100

    /// All pre-generated messages, ordered oldest → newest.
    private var allMessages: [ChatItem] = []
    private var oldestDeliveredIndex: Int = 0

    /// Tracks incoming messages so the UI can find the last one for reply/forward.
    private(set) var lastReceivedMessage: ChatMessage?

    private let contacts: [(name: String, sender: ChatMessage.Sender)] = [
        ("Alice", .other(name: "Alice")),
        ("Bob", .other(name: "Bob")),
    ]

    private let sampleTexts: [String] = [
        "Hey! How's it going?",
        "Not bad, just working on the new project.",
        "That sounds interesting! What are you building?",
        "A chat component for iOS, actually.",
        "Oh nice! UIKit or SwiftUI?",
        "UIKit with collection view. DiffableDataSource is pretty slick.",
        "Totally agree. The pagination must be tricky though.",
        "Yeah, keeping scroll position when prepending is the hard part.",
        "Have you tried the content offset trick?",
        "Yep, save old height, apply, measure new height, adjust offset.",
        "Classic. Works well?",
        "Works great. No visible jump at all.",
        "That's awesome!",
        "Thanks! Should be done by end of day.",
        "Can't wait to see it.",
        "I'll send you a build when it's ready.",
        "Perfect!",
        "By the way, did you see the new Xcode update?",
        "Not yet, any good?",
        "Massive improvements to the build system.",
        "Nice, I'll check it out.",
        "Also the new simulator is way faster.",
        "That's great news.",
        "Want to grab lunch later?",
        "Sure, the usual place?",
        "Sounds good. 12:30?",
        "Works for me!",
        "See you then.",
        "Later!",
        "One more thing — can you review my PR?",
        "Sure, send me the link.",
        "Just pushed it to GitHub.",
        "Looking at it now...",
        "The tests all pass locally.",
        "Looks clean. Just one minor comment on the naming.",
        "Which part?",
        "The ChatPage struct — maybe rename hasNextPage to hasOlderMessages?",
        "Good call, that's more descriptive.",
        "Approved! Nice work.",
        "Thanks for the quick review!",
    ]

    private let sampleImages = [
        "photo", "camera", "mountain.2", "sun.max",
        "moon.stars", "cloud.sun", "leaf", "flame",
    ]

    // MARK: - Init

    init() {
        let calendar = Calendar.current
        let now = Date()
        var messages: [ChatItem] = []
        var currentDate: Date = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        var lastDateLabel: String?

        for i in 0..<totalMessages {
            let minuteOffset = Int.random(in: 1...30)
            currentDate = calendar.date(byAdding: .minute, value: minuteOffset, to: currentDate) ?? currentDate

            let dayLabel = Self.dayLabel(for: currentDate)
            if dayLabel != lastDateLabel {
                messages.append(.dateSeparator(text: dayLabel))
                lastDateLabel = dayLabel
            }

            let sender: ChatMessage.Sender
            if i % 5 == 0 || i % 5 == 3 {
                sender = .me
            } else {
                sender = contacts[i % contacts.count].sender
            }

            if i % 8 == 7 {
                let symbol = sampleImages[i % sampleImages.count]
                let msg = ChatMessage.symbol(symbol, from: sender, at: currentDate,
                                              isRead: sender.isMe)
                messages.append(.message(msg))
            } else {
                let text = sampleTexts[i % sampleTexts.count]
                let msg = ChatMessage.text(text, from: sender, at: currentDate,
                                           isRead: sender.isMe)
                messages.append(.message(msg))
            }
        }

        allMessages = messages
        oldestDeliveredIndex = max(0, allMessages.count - pageSize)
    }

    // MARK: - ChatServiceProtocol — Loading

    func loadInitialMessages() {
        let page = Array(allMessages[oldestDeliveredIndex...])
        let hasMore = oldestDeliveredIndex > 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateSubject.send(.initial(items: page, hasMorePages: hasMore))
        }
    }

    func loadOlderMessages() {
        guard oldestDeliveredIndex > 0 else {
            updateSubject.send(.prepend(items: [], hasMorePages: false))
            return
        }

        let end = oldestDeliveredIndex
        let start = max(0, end - pageSize)
        oldestDeliveredIndex = start

        let page = Array(allMessages[start..<end])
        let hasMore = start > 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateSubject.send(.prepend(items: page, hasMorePages: hasMore))
        }
    }

    // MARK: - Unsend

    func unsend(_ item: ChatItem) {
        updateSubject.send(.remove(items: [item]))
    }

    // MARK: - Typing Indicator

    private var typingItem: ChatItem?

    private func showTypingIndicator() {
        guard typingItem == nil else { return }
        let item = ChatItem.typingIndicator()
        typingItem = item
        updateSubject.send(.append(items: [item], scrollToBottom: false))
    }

    private func hideTypingIndicator() {
        guard let item = typingItem else { return }
        typingItem = nil
        updateSubject.send(.remove(items: [item]))
    }

    // MARK: - Simulated Incoming Reply

    /// Shows typing indicator, then publishes an incoming reply after a delay.
    func scheduleIncomingReply() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.showTypingIndicator()
        }

        let delay = Double.random(in: 1.5...3.0)
        guard let contact = contacts.randomElement() else { return }
        let sender = contact.sender
        let replies = [
            "Got it!", "Interesting!", "Tell me more.",
            "Sounds good to me.", "Haha, nice one!",
            "I'll think about it.", "Makes sense.",
            "Absolutely!", "Let me check...",
            "That's a great point.",
        ]
        guard let text = replies.randomElement() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.hideTypingIndicator()
            let msg = ChatMessage.text(text, from: sender, isRead: false)
            self?.lastReceivedMessage = msg
            self?.updateSubject.send(.append(items: [.message(msg)], scrollToBottom: false))
        }
    }

    // MARK: - Ambient Chat Simulation

    private var ambientTimer: Timer?

    private let ambientMessages: [String] = [
        "Hey, are you still there?",
        "Just saw something hilarious",
        "Did you get my last message?",
        "Check this out when you get a chance",
        "I'm heading out soon, let me know",
        "Btw, the meeting got moved to 3pm",
        "Any updates on the project?",
        "Lunch was amazing today",
        "Can you believe this weather?",
        "I just finished that book you recommended",
        "We should catch up this weekend",
        "Running a bit late, be there in 10",
        "Have you tried that new restaurant?",
        "Just pushed the fix, can you pull?",
        "This bug is driving me crazy",
        "Finally got the tests passing!",
        "Quick question — are you free tomorrow?",
        "Forgot to mention earlier...",
        "Sounds like a plan!",
        "Let me think about it and get back to you",
    ]

    func startAmbientChat() {
        scheduleNextAmbientMessage()
    }

    func stopAmbientChat() {
        ambientTimer?.invalidate()
        ambientTimer = nil
    }

    private func scheduleNextAmbientMessage() {
        let delay = Double.random(in: 3.0...10.0)
        ambientTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.sendAmbientMessage()
            self?.scheduleNextAmbientMessage()
        }
    }

    private func sendAmbientMessage() {
        guard let contact = contacts.randomElement(),
              let text = ambientMessages.randomElement() else { return }
        let sender = contact.sender

        showTypingIndicator()

        let typingDuration = Double.random(in: 1.0...3.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + typingDuration) { [weak self] in
            self?.hideTypingIndicator()

            if Int.random(in: 0..<7) == 0 {
                let symbol = self?.sampleImages.randomElement() ?? "photo"
                let msg = ChatMessage.symbol(symbol, from: sender, isRead: false)
                self?.lastReceivedMessage = msg
                self?.updateSubject.send(.append(items: [.message(msg)], scrollToBottom: false))
            } else {
                let msg = ChatMessage.text(text, from: sender, isRead: false)
                self?.lastReceivedMessage = msg
                self?.updateSubject.send(.append(items: [.message(msg)], scrollToBottom: false))
            }
        }
    }

    // MARK: - Helpers

    private static func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
