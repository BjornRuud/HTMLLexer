import XCTest
@testable import HTMLLexer

final class BidirectionalCollectionTests: XCTestCase {
    func testDropLastWhereSubstring() {
        let reference = "Hello, World!   "
        var trimmed = reference[...].dropLast {
            CharacterSet.asciiWhitespace.contains($0)
        }
        XCTAssertEqual(trimmed, "Hello, World!")

        trimmed = trimmed.dropLast {
            CharacterSet.asciiWhitespace.contains($0)
        }
        XCTAssertEqual(trimmed, "Hello, World!")
    }

    func testDropLastWhereUTF8() {
        let reference = "Hello, World!   ".utf8
        var trimmed = reference[...].dropLast {
            CharacterSet.asciiWhitespace.contains(Unicode.Scalar($0))
        }
        XCTAssertEqual(String(trimmed), "Hello, World!")

        trimmed = trimmed.dropLast {
            CharacterSet.asciiWhitespace.contains(Unicode.Scalar($0))
        }
        XCTAssertEqual(String(trimmed), "Hello, World!")
    }
}
