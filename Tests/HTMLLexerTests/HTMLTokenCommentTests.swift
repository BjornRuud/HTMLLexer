import XCTest
@testable import HTMLLexer

final class HTMLTokenCommentTests: XCTestCase {
    func testCommentTag() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("<!-- Foo -->")
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.comment(" Foo ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(text.count, 0)
    }

    func testCommentMalformed() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("<!- Foo")
        let textLength = text.count
        XCTAssertNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, textLength)
    }

    func testCommentNoEnd() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("<!-- Foo")
        let textLength = text.count
        XCTAssertNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, textLength)
    }

    func testCommentDoubleEnd() throws {
        let parser = HTMLTokenParser.comment
        var text = Substring("<!-- Foo -->-->")
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.comment(" Foo ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(text.count, 3)
    }
}