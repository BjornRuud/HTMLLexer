import XCTest
@testable import HTMLLexer

final class HTMLTokenStartTagTests: XCTestCase {
    func testPlain() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("b>")
        let token = try parser.parse(&text)
        let reference = HTMLParsingToken.tagStart(name: "b", attributes: [], isSelfClosing: false)
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpace() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("b >")
        let token = try parser.parse(&text)
        let reference = HTMLParsingToken.tagStart(name: "b", attributes: [], isSelfClosing: false)
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSelfClosing() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("b/>")
        let token = try parser.parse(&text)
        let reference = HTMLParsingToken.tagStart(name: "b", attributes: [], isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }

    func testPlainWithSpaceAndSelfClosing() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("b />")
        let token = try parser.parse(&text)
        let reference = HTMLParsingToken.tagStart(name: "b", attributes: [], isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }

    func testInvalidName() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("@>")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testAttributesSingle() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("b foo1 = 'bar1'/>")
        let token = try parser.parse(&text)
        let attributes: [HTMLParsingToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1")
        ]
        let reference = HTMLParsingToken.tagStart(name: "b", attributes: attributes, isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }

    func testAttributes() throws {
        let parser = HTMLTokenParser.StartTag()
        var text = Substring("b foo1=bar1 foo2='bar2' foo3 = \"bar3\" foo4 />")
        let token = try parser.parse(&text)
        let attributes: [HTMLParsingToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1"),
            .init(name: "foo2", value: "bar2"),
            .init(name: "foo3", value: "bar3"),
            .init(name: "foo4", value: nil)
        ]
        let reference = HTMLParsingToken.tagStart(name: "b", attributes: attributes, isSelfClosing: true)
        XCTAssertEqual(token, reference)
    }
}
