import Foundation
import Testing
@testable import HTMLLexer

@Suite struct BidirectionalCollectionTests {
    @Test func dropLastWhereSubstring() {
        let reference = "Hello, World!   "
        var trimmed = reference[...].dropLast {
            CharacterSet.asciiWhitespace.contains($0)
        }
        #expect(trimmed == "Hello, World!")

        trimmed = trimmed.dropLast {
            CharacterSet.asciiWhitespace.contains($0)
        }
        #expect(trimmed == "Hello, World!")
    }

    @Test func dropLastWhereUTF8() {
        let reference = "Hello, World!   ".utf8
        var trimmed = reference[...].dropLast {
            CharacterSet.asciiWhitespace.contains(Unicode.Scalar($0))
        }
        #expect(String(trimmed) == "Hello, World!")

        trimmed = trimmed.dropLast {
            CharacterSet.asciiWhitespace.contains(Unicode.Scalar($0))
        }
        #expect(String(trimmed) == "Hello, World!")
    }
}
