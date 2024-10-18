import Foundation
import Testing
@testable import HTMLLexer

@Suite struct TagAttributeTests {
    @Test func empty() throws {
        let parser = TagAttribute()
        let text = "".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func nameOnly() throws {
        let parser = TagAttribute()
        let text = "custom".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == nil)
    }

    @Test func singleQuoteValue() throws {
        let parser = TagAttribute()
        let text = "custom = 'foo'".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == "foo")
    }

    @Test func singleQuoteValueNoEnd() throws {
        let parser = TagAttribute()
        let text = "custom = 'foo".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func doubleQuoteValue() throws {
        let parser = TagAttribute()
        let text = "custom = \"foo\"".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == "foo")
    }

    @Test func doubleQuoteValueNoEnd() throws {
        let parser = TagAttribute()
        let text = "custom = \"foo".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test("Valid unquoted values", arguments: [
        ("foo", "foo"),
        ("f/o", "f/o"),
        ("f😀o", "f😀o"),
        ("foo ", "foo"),
        ("foo>", "foo"),
        ("foo/>", "foo"),
        ("foo//>", "foo/"),
    ])
    func unquotedValue(textAndRef: (String, String)) throws {
        let (text, refValue) = textAndRef
        let parser = TagAttributeNonQuotedValue()
        var input = text.utf8[...]
        let value = try parser.parse(&input)
        #expect(String(value) == refValue)
    }

    @Test("Invalid unquoted values", arguments: [
        "",
    ])
    func unquotedValueInvalid(text: String) throws {
        let parser = TagAttributeNonQuotedValue()
        var input = text.utf8[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func multiple() throws {
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
        #expect(attributes == reference)
    }

    @Test("End of attribute name", arguments: [
        ("foo anotherFoo", [HTMLToken.TagAttribute(name: "foo", value: nil), .init(name: "anotherFoo", value: nil)]),
        ("foo>", [.init(name: "foo", value: nil)]),
        ("foo/>", [.init(name: "foo", value: nil)]),
        ("foo=bar>", [.init(name: "foo", value: "bar")]),
    ])
    func tagEnd(textAndRef: (String, [HTMLToken.TagAttribute])) throws {
        let parser = TagAttributes()
        let (text, refTokens) = textAndRef
        var input = text.utf8[...]
        let attributes = try parser.parse(&input)
        #expect(attributes == refTokens)
    }
}
