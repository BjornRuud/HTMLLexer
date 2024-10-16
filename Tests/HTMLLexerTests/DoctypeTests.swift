import XCTest
@testable import HTMLLexer

final class DoctypeTests: XCTestCase {
    func testDoctype() throws {
        let parser = DocType()
        let text = "DOCTYPE html>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "DOCTYPE", type: "html", legacy: nil)
        XCTAssertEqual(token, reference)
    }

    func testDoctypeInvalid() throws {
        let parser = DocType()
        let text = "DOC html>".utf8
        var input = text[...]
        XCTAssertThrowsError(try parser.parse(&input))
    }

    func testDocTypeInverse() throws {
        let parser = DocType()
        let text = "doctype HTML>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "doctype", type: "HTML", legacy: nil)
        XCTAssertEqual(token, reference)
    }

    func testDocTypeMixed() throws {
        let parser = DocType()
        let text = "dOcTyPe HtMl>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "dOcTyPe", type: "HtMl", legacy: nil)
        XCTAssertEqual(token, reference)
    }

    func testDoctypeLegacy() throws {
        let parser = DocType()
        let text = #"DOCTYPE html SYSTEM "about:legacy-compat">"#.utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "DOCTYPE", type: "html", legacy: #"SYSTEM "about:legacy-compat""#)
        XCTAssertEqual(token, reference)
    }
}
