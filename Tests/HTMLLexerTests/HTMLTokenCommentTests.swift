import XCTest
@testable import HTMLLexer

final class HTMLTokenCommentTests: XCTestCase {
    func testCommentTag() throws {
        let parser = Comment()
        let text = "-- Foo -->".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.comment(" Foo ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(input.count, 0)
    }

    func testCommentMalformed() throws {
        let parser = Comment()
        let text = "- Foo".utf8
        var input = text[...]
        let textLength = text.count
        XCTAssertThrowsError(try parser.parse(&input))
        XCTAssertEqual(input.count, textLength)
    }

    func testCommentNoEnd() throws {
        let parser = Comment()
        let text = "-- Foo".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
        XCTAssertEqual(input.count, 4)
    }

    func testCommentDoubleEnd() throws {
        let parser = Comment()
        let text = "-- Foo -->-->".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.comment(" Foo ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(input.count, 3)
    }
}
