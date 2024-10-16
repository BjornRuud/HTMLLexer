import XCTest
@testable import HTMLLexer

final class EndTagTests: XCTestCase {
    func testPlain() throws {
        let parser = EndTag()
        let text = "/b>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagEnd(name: "b")
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpace() throws {
        let parser = EndTag()
        let text = "/b >".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagEnd(name: "b")
        XCTAssertEqual(token, reference)
    }

    func testInvalidName() throws {
        let parser = EndTag()
        let text = "/@ >".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }

    func testInvalidAttribute() throws {
        let parser = EndTag()
        let text = "/b foo='bar'>".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }
}
