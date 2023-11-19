import XCTest
@testable import HTMLLexer

final class HTMLTokenCommentTests: XCTestCase {
    func testCommentTag() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("!-- Foo -->").unicodeScalars
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.comment(" Foo ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(text.count, 0)
    }

    func testCommentMalformed() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("!- Foo").unicodeScalars
        let textLength = text.count
        XCTAssertNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, textLength)
    }

    func testCommentNoEnd() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("!-- Foo").unicodeScalars
        XCTAssertNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, 4)
    }

    func testCommentDoubleEnd() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("!-- Foo -->-->").unicodeScalars
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.comment(" Foo ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(text.count, 3)
    }
}
