import XCTest
@testable import HTMLLexer

final class CDataTests: XCTestCase {
    func testCDataTag() throws {
        let parser = CData()
        let text = "[CDATA[x<y]]>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.cdata("x<y")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(input.count, 0)
    }

    func testCDataTagWithWhitespace() throws {
        let parser = CData()
        let text = "[CDATA[ x < y ]]>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.cdata(" x < y ")
        XCTAssertEqual(token, reference)
        XCTAssertEqual(input.count, 0)
    }
}
