import Testing
@testable import HTMLLexer

@Suite struct ByteOrderMarkTests {
    @Test func byteOrderMark() throws {
        let parser = ByteOrderMark()
        let text = "\u{FEFF}".utf8
        var input = text[...]
        #expect(try parser.parse(&input) != nil)
        #expect(input.count == 0)
    }

    @Test func byteOrderMarkLater() throws {
        let parser = ByteOrderMark()
        let text = " \u{FEFF}".utf8
        var input = text[...]
        #expect(try parser.parse(&input) == nil)
        #expect(input.count == 4) // U+FEFF is 3 bytes in UTF-8
    }
}
