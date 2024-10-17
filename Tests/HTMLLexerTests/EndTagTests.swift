import Testing
@testable import HTMLLexer

@Suite struct EndTagTests {
    @Test func plain() throws {
        let parser = EndTag()
        let text = "/b>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagEnd(name: "b")
        #expect(token == reference)
    }

    @Test func plainWithSpace() throws {
        let parser = EndTag()
        let text = "/b >".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.tagEnd(name: "b")
        #expect(token == reference)
    }

    @Test func invalidName() throws {
        let parser = EndTag()
        let text = "/@ >".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func invalidAttribute() throws {
        let parser = EndTag()
        let text = "/b foo='bar'>".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }
}
