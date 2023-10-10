import XCTest
@testable import HTMLLexer

final class HTMLTokenParserTests: XCTestCase {
    func testByteOrderMark() throws {
        let parser = HTMLTokenParser.byteOrderMark

        var bomFirst = Substring("\u{FEFF}")
        XCTAssertNotNil(try? parser.parse(&bomFirst))
        XCTAssertEqual(bomFirst.count, 0)

        var bomLater = Substring(" \u{FEFF}")
        XCTAssertNil(try? parser.parse(&bomLater))
        XCTAssertEqual(bomLater.count, 2)
    }
}
