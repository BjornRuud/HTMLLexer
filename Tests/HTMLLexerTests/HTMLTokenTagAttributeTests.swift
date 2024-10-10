import XCTest
@testable import HTMLLexer

final class HTMLTokenTagAttributeTests: XCTestCase {
    func testTagAttributeSingle() throws {
        let parser = TagAttribute()
        var text = Substring("custom")
        let attribute = try parser.parse(&text)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertNil(attribute.value)
    }

    func testTagAttributeSingleQuote() throws {
        let parser = TagAttribute()
        var text = Substring("custom = 'foo'")
        let attribute = try parser.parse(&text)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertEqual(attribute.value, "foo")
    }

    func testTagAttributeSingleQuoteNoEnd() throws {
        let parser = TagAttribute()
        var text = Substring("custom = 'foo")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testTagAttributeDoubleQuote() throws {
        let parser = TagAttribute()
        var text = Substring("custom = \"foo\"")
        let attribute = try parser.parse(&text)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertEqual(attribute.value, "foo")
    }

    func testTagAttributeDoubleQuoteNoEnd() throws {
        let parser = TagAttribute()
        var text = Substring("custom = \"foo")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testTagAttributeEmpty() throws {
        let parser = TagAttribute()
        var text = Substring("")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testTagAttributeUnquoted() throws {
        let parser = TagAttribute()
        var text = Substring("custom = foo")
        let attribute = try parser.parse(&text)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertEqual(attribute.value, "foo")
    }

    func testTagAttributeUnquotedEndSlash() throws {
        let parser = TagAttribute()
        var text = Substring("custom = foo/")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testTagAttributes() throws {
        let parser = TagAttributes()
        var text = Substring("foo1 = 'bar1' foo2='bar2' foo3 foo4=bar4")
        let attributes = try parser.parse(&text)
        let reference: [HTMLParsingToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1"),
            .init(name: "foo2", value: "bar2"),
            .init(name: "foo3", value: nil),
            .init(name: "foo4", value: "bar4")
        ]
        XCTAssertEqual(attributes, reference)
    }
}
