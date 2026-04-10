import XCTest
@testable import ChatKit

final class ChatKitTests: XCTestCase {

    func testChatMessageTextConvenience() {
        let message = ChatMessage.text("Hello", from: .me)
        XCTAssertEqual(message.text, "Hello")
        XCTAssertTrue(message.sender.isMe)
        XCTAssertNil(message.imageSource)
        XCTAssertNil(message.replyingTo)
        XCTAssertNil(message.forwardedFrom)
    }

    func testChatMessageSymbolConvenience() {
        let message = ChatMessage.symbol("star", from: .other(name: "Alice"))
        XCTAssertNil(message.text)
        XCTAssertEqual(message.imageSource, .symbol("star"))
        XCTAssertFalse(message.sender.isMe)
    }

    func testChatMessageImageConvenience() {
        let url = URL(string: "https://example.com/photo.jpg")!
        let message = ChatMessage.image(.remote(url), from: .me)
        XCTAssertNil(message.text)
        XCTAssertEqual(message.imageSource, .remote(url))
    }

    func testChatMessageReplyConvenience() {
        let original = ChatMessage.text("Original", from: .other(name: "Bob"))
        let reply = ChatMessage.reply(to: original, text: "Reply", from: .me)
        XCTAssertEqual(reply.text, "Reply")
        XCTAssertEqual(reply.replyingTo?.value, original)
    }

    func testChatItemAsMessage() {
        let message = ChatMessage.text("Hi", from: .me)
        let item = ChatItem.message(message)
        XCTAssertEqual(item.asMessage, message)

        let separator = ChatItem.dateSeparator(text: "Today")
        XCTAssertNil(separator.asMessage)
    }

    func testImageSourceEquality() {
        let url = URL(string: "https://example.com/a.png")!
        XCTAssertEqual(ImageSource.symbol("star"), ImageSource.symbol("star"))
        XCTAssertNotEqual(ImageSource.symbol("star"), ImageSource.symbol("moon"))
        XCTAssertEqual(ImageSource.remote(url), ImageSource.remote(url))
    }
}
