import XCTest
@testable import HTMLLexer

final class HTMLTokenByteOrderMarkTests: XCTestCase {
    func testByteOrderMark() throws {
        let parser = ByteOrderMark()
        let text = "\u{FEFF}".utf8
        var input = text[...]
        XCTAssertNotNil(try parser.parse(&input))
        XCTAssertEqual(input.count, 0)
    }

    func testByteOrderMarkLater() throws {
        let parser = ByteOrderMark()
        let text = " \u{FEFF}".utf8
        var input = text[...]
        XCTAssertNil(try parser.parse(&input))
        XCTAssertEqual(input.count, 4) // U+FEFF is 3 bytes in UTF-8
    }
}
