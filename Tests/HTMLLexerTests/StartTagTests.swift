import Testing
@testable import HTMLLexer

@Suite struct StartTagTests {
    @Test func plain() throws {
        let parser = StartTag()
        let text = "b>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: false)
        #expect(token == reference)
    }

    @Test func plainWithSpace() throws {
        let parser = StartTag()
        let text = "b >".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: false)
        #expect(token == reference)
    }

    @Test func plainWithSelfClosing() throws {
        let parser = StartTag()
        let text = "b/>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: true)
        #expect(token == reference)
    }

    @Test func plainWithSpaceAndSelfClosing() throws {
        let parser = StartTag()
        let text = "b />".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagStart(name: "b", attributes: [], isSelfClosing: true)
        #expect(token == reference)
    }

    @Test func invalidName() throws {
        let parser = StartTag()
        let text = "@>".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func attributesSingle() throws {
        let parser = StartTag()
        let text = "b foo1 = 'bar1'/>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let attributes: [HTMLToken.TagAttribute] = [
            .init(name: "foo1", value: "bar1")
        ]
        let reference = HTMLToken.tagStart(name: "b", attributes: attributes, isSelfClosing: true)
        #expect(token == reference)
    }

    @Test func attributes() throws {
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
        #expect(token == reference)
    }
}
