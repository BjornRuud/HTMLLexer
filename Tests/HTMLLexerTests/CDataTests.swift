import Testing
@testable import HTMLLexer

@Suite struct CDataTests {
    @Test func cDataTag() throws {
        let parser = CData()
        let text = "[CDATA[x<y]]>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.cdata("x<y")
        #expect(token == reference)
        #expect(input.count == 0)
    }

    @Test func cDataTagWithWhitespace() throws {
        let parser = CData()
        let text = "[CDATA[ x < y ]]>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.cdata(" x < y ")
        #expect(token == reference)
        #expect(input.count == 0)
    }
}
