import XCTest
@testable import HTMLLexer

final class HTMLTokenEndTagTests: XCTestCase {
    func testPlain() throws {
        let parser = HTMLTokenParser.endTag
        var text = Substring("/b>").unicodeScalars
        let token = try parser.parse(&text)
        let reference = HTMLToken.tagEnd(name: "b")
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpace() throws {
        let parser = HTMLTokenParser.endTag
        var text = Substring("/b >").unicodeScalars
        let token = try parser.parse(&text)
        let reference = HTMLToken.tagEnd(name: "b")
        XCTAssertEqual(token, reference)
    }

    func testInvalidName() throws {
        let parser = HTMLTokenParser.endTag
        var text = Substring("/@ >").unicodeScalars
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testInvalidAttribute() throws {
        let parser = HTMLTokenParser.endTag
        var text = Substring("/b foo='bar'>").unicodeScalars
        XCTAssertThrowsError(try parser.parse(&text))
    }
}
