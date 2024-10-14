import XCTest
@testable import HTMLLexer

final class HTMLTokenTagAttributeTests: XCTestCase {
    func testTagAttributeSingle() throws {
        let parser = TagAttribute()
        let text = "custom".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertNil(attribute.value)
    }

    func testTagAttributeSingleQuote() throws {
        let parser = TagAttribute()
        let text = "custom = 'foo'".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertEqual(attribute.value, "foo")
    }

    func testTagAttributeSingleQuoteNoEnd() throws {
        let parser = TagAttribute()
        let text = "custom = 'foo".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }

    func testTagAttributeDoubleQuote() throws {
        let parser = TagAttribute()
        let text = "custom = \"foo\"".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertEqual(attribute.value, "foo")
    }

    func testTagAttributeDoubleQuoteNoEnd() throws {
        let parser = TagAttribute()
        let text = "custom = \"foo".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }

    func testTagAttributeEmpty() throws {
        let parser = TagAttribute()
        let text = "".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }

    func testTagAttributeUnquoted() throws {
        let parser = TagAttribute()
        let text = "custom = foo".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        XCTAssertEqual(attribute.name, "custom")
        XCTAssertEqual(attribute.value, "foo")
    }

    func testTagAttributes() throws {
        let parser = TagAttributes()
        let text = "foo1 = 'bar1' foo2='bar2' foo3 foo4=bar4".utf8
        var input = text[...]
        let attributes = try parser.parse(&input)
        let reference: [HTMLToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1"),
            .init(name: "foo2", value: "bar2"),
            .init(name: "foo3", value: nil),
            .init(name: "foo4", value: "bar4")
        ]
        XCTAssertEqual(attributes, reference)
    }
}
