import XCTest
@testable import HTMLLexer

final class HTMLTokenStartTagTests: XCTestCase {
    func testPlain() throws {
        let parser = StartTag()
        let text = "b>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: false)
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpace() throws {
        let parser = StartTag()
        let text = "b >".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: false)
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSelfClosing() throws {
        let parser = StartTag()
        let text = "b/>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpaceAndSelfClosing() throws {
        let parser = StartTag()
        let text = "b />".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }

    func testInvalidName() throws {
        let parser = StartTag()
        let text = "@>".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }

    func testAttributesSingle() throws {
        let parser = StartTag()
        let text = "b foo1 = 'bar1'/>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let attributes: [HTMLToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1")
        ]
        let reference = HTMLToken.tagStart(name: "b", attributes: attributes, isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }

    func testAttributes() throws {
        let parser = StartTag()
        let text = "b foo1=bar1 foo2='bar2' foo3 = \"bar3\" foo4 />".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let attributes: [HTMLToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1"),
            .init(name: "foo2", value: "bar2"),
            .init(name: "foo3", value: "bar3"),
            .init(name: "foo4", value: nil)
        ]
        let reference = HTMLToken.tagStart(name: "b", attributes: attributes, isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }
}
