import Testing
@testable import HTMLLexer

@Suite struct TagAttributeTests {
    @Test func tagAttributeSingle() throws {
        let parser = TagAttribute()
        let text = "custom".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == nil)
    }

    @Test func tagAttributeSingleQuote() throws {
        let parser = TagAttribute()
        let text = "custom = 'foo'".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == "foo")
    }

    @Test func tagAttributeSingleQuoteNoEnd() throws {
        let parser = TagAttribute()
        let text = "custom = 'foo".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func tagAttributeDoubleQuote() throws {
        let parser = TagAttribute()
        let text = "custom = \"foo\"".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == "foo")
    }

    @Test func tagAttributeDoubleQuoteNoEnd() throws {
        let parser = TagAttribute()
        let text = "custom = \"foo".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func tagAttributeEmpty() throws {
        let parser = TagAttribute()
        let text = "".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func tagAttributeUnquoted() throws {
        let parser = TagAttribute()
        let text = "custom = foo".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == "foo")
    }

    @Test func tagAttributes() throws {
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
}
