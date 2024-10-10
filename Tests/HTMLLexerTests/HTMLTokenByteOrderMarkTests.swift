import XCTest
@testable import HTMLLexer

final class HTMLTokenByteOrderMarkTests: XCTestCase {
    func testByteOrderMark() throws {
        let parser = HTMLTokenParser.ByteOrderMark()
        var text = Substring("\u{FEFF}")
        XCTAssertNotNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, 0)
    }

    func testByteOrderMarkLater() throws {
        let parser = HTMLTokenParser.ByteOrderMark()
        var text = Substring(" \u{FEFF}")
        XCTAssertNil(try? parser.parse(&text))
        XCTAssertEqual(text.count, 2)
    }
}
