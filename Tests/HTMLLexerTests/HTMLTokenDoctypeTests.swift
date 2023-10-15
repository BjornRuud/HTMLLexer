import XCTest
@testable import HTMLLexer

final class HTMLTokenDoctypeTests: XCTestCase {
    func testDoctype() throws {
        let parser = HTMLTokenParser.doctype
        var text = Substring("!DOCTYPE html>")
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.doctype(name: "DOCTYPE", type: "html", legacy: nil)
        XCTAssertEqual(token, reference)
    }

    func testDoctypeInvalid() throws {
        let parser = HTMLTokenParser.doctype
        var text = Substring("!DOC html>")
        XCTAssertNil(try? parser.parse(&text))
    }

    func testDocTypeInverse() throws {
        let parser = HTMLTokenParser.doctype
        var text = Substring("!doctype HTML>")
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.doctype(name: "doctype", type: "HTML", legacy: nil)
        XCTAssertEqual(token, reference)
    }

    func testDocTypeMixed() throws {
        let parser = HTMLTokenParser.doctype
        var text = Substring("!dOcTyPe HtMl>")
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.doctype(name: "dOcTyPe", type: "HtMl", legacy: nil)
        XCTAssertEqual(token, reference)
    }

    func testDoctypeLegacy() throws {
        let parser = HTMLTokenParser.doctype
        var text = Substring(#"!DOCTYPE html SYSTEM "about:legacy-compat">"#)
        let token = try XCTUnwrap(try parser.parse(&text))
        let reference = HTMLToken.doctype(name: "DOCTYPE", type: "html", legacy: #"SYSTEM "about:legacy-compat""#)
        XCTAssertEqual(token, reference)
    }
}
