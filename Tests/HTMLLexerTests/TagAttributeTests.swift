import Foundation
import Testing
@testable import HTMLLexer

@Suite struct TagAttributeTests {
    private static var invalidNameCharacters: [String] {
        var invalidChars = "\"'".map { "\($0)" }
        invalidChars += (0x7F...0x9F).map { "\(Unicode.Scalar($0)!)" }
        invalidChars += (0xFDD0...0xFDEF).map { "\(Unicode.Scalar($0)!)" }
        invalidChars += [
            0xFFFE,
            0xFFFF,
            0x1FFFE,
            0x1FFFF,
            0x2FFFE,
            0x2FFFF,
            0x3FFFE,
            0x3FFFF,
            0x4FFFE,
            0x4FFFF,
            0x5FFFE,
            0x5FFFF,
            0x6FFFE,
            0x6FFFF,
            0x7FFFE,
            0x7FFFF,
            0x8FFFE,
            0x8FFFF,
            0x9FFFE,
            0x9FFFF,
            0xAFFFE,
            0xAFFFF,
            0xBFFFE,
            0xBFFFF,
            0xCFFFE,
            0xCFFFF,
            0xDFFFE,
            0xDFFFF,
            0xEFFFE,
            0xEFFFF,
            0xFFFFE,
            0xFFFFF,
            0x10FFFE,
            0x10FFFF,
        ].map { "\(Unicode.Scalar($0)!)" }
        return invalidChars
    }

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

    @Test("Invalid name characters", arguments: Self.invalidNameCharacters)
    func invalidName(invalidChar: String) throws {
        let parser = TagAttribute()
        let text = "cus\(invalidChar)tom".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
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

    @Test func unquotedValue() throws {
        let parser = TagAttribute()
        let text = "custom = foo".utf8
        var input = text[...]
        let attribute = try parser.parse(&input)
        #expect(attribute.name == "custom")
        #expect(attribute.value == "foo")
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
}
