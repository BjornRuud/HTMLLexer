import XCTest
@testable import HTMLLexer

final class HTMLTokenByteOrderMarkTests: XCTestCase {
    func testByteOrderMark() throws {
        let parser = HTMLTokenParser.byteOrderMark
        var text = Substring("\u{FEFF}").unicodeScalars
        XCTAssertNotNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, 0)
    }

    func testByteOrderMarkLater() throws {
        let parser = HTMLTokenParser.byteOrderMark
        var text = Substring(" \u{FEFF}").unicodeScalars
        XCTAssertNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, 2)
    }
}
