import XCTest
@testable import HTMLLexer

final class HTMLTokenEndTagTests: XCTestCase {
    func testPlain() throws {
        let parser = HTMLTokenParser.EndTag()
        var text = Substring("/b>")
        let token = try parser.parse(&text)
        let reference = HTMLParsingToken.tagEnd(name: "b")
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpace() throws {
        let parser = HTMLTokenParser.EndTag()
        var text = Substring("/b >")
        let token = try parser.parse(&text)
        let reference = HTMLParsingToken.tagEnd(name: "b")
        XCTAssertEqual(token, reference)
    }

    func testInvalidName() throws {
        let parser = HTMLTokenParser.EndTag()
        var text = Substring("/@ >")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testInvalidAttribute() throws {
        let parser = HTMLTokenParser.EndTag()
        var text = Substring("/b foo='bar'>")
        XCTAssertThrowsError(try parser.parse(&text))
    }
}
