import Testing
@testable import HTMLLexer

@Suite struct CommentTests {
    @Test func commentTag() throws {
        let parser = Comment()
        let text = "-- Foo -->".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.comment(" Foo ")
        #expect(token == reference)
        #expect(input.count == 0)
    }

    @Test func commentMalformed() throws {
        let parser = Comment()
        let text = "- Foo".utf8
        var input = text[...]
        let textLength = text.count
        #expect(throws: (any Error).self) { try parser.parse(&input) }
        #expect(input.count == textLength)
    }

    @Test func commentNoEnd() throws {
        let parser = Comment()
        let text = "-- Foo".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
        #expect(input.count == 4)
    }

    @Test func commentDoubleEnd() throws {
        let parser = Comment()
        let text = "-- Foo -->-->".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.comment(" Foo ")
        #expect(token == reference)
        #expect(input.count == 3)
    }
}
