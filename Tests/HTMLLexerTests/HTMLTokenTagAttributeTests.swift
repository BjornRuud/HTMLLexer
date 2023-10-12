import XCTest
@testable import HTMLLexer

final class HTMLTokenTagAttributeTests: XCTestCase {
    func testTagAttributeSingle() throws {
        let parser = HTMLTokenParser.tagAttribute
        let text = Substring("custom ")
        let referenceName = Substring("custom")
        let attribute = try parser.parse(text)
        XCTAssertEqual(attribute.name, referenceName)
        XCTAssertNil(attribute.value)
    }

    func testTagAttributeSingleQuote() throws {
        let parser = HTMLTokenParser.tagAttribute
        let text = Substring("custom = 'foo'")
        let referenceName = Substring("custom")
        let referenceValue = Substring("foo")
        let attribute = try parser.parse(text)
        XCTAssertEqual(attribute.name, referenceName)
        XCTAssertEqual(attribute.value, referenceValue)
    }

    func testTagAttributeSingleQuoteNoStart() throws {
        let parser = HTMLTokenParser.tagAttribute
        let text = Substring("custom = foo'")
        XCTAssertThrowsError(try parser.parse(text))
    }

    func testTagAttributeSingleQuoteNoEnd() throws {
        let parser = HTMLTokenParser.tagAttribute
        let text = Substring("custom = 'foo")
        XCTAssertThrowsError(try parser.parse(text))
    }

    func testTagAttributeDoubleQuote() throws {
        let parser = HTMLTokenParser.tagAttribute
        var text = Substring("custom = \"foo\"")
        let referenceName = Substring("custom")
        let referenceValue = Substring("foo")
        let attribute = try parser.parse(&text)
        XCTAssertEqual(attribute.name, referenceName)
        XCTAssertEqual(attribute.value, referenceValue)
    }

    func testTagAttributeDoubleQuoteNoStart() throws {
        let parser = HTMLTokenParser.tagAttribute
        var text = Substring("custom = foo\"")
        XCTAssertThrowsError(try parser.parse(&text))
    }

    func testTagAttributeDoubleQuoteNoEnd() throws {
        let parser = HTMLTokenParser.tagAttribute
        var text = Substring("custom = \"foo")
        XCTAssertThrowsError(try parser.parse(&text))
    }

//    func testTagAttributeUnquoted() throws {
//        let parser = HTMLTokenParser.tagAttribute
//        var text = Substring("custom = foo")
//        let referenceName = Substring("custom")
//        let referenceValue = Substring("foo")
//        let attribute = try parser.parse(&text)
//        XCTAssertEqual(attribute.name, referenceName)
//        XCTAssertEqual(attribute.value, referenceValue)
//    }
//
//    func testTagAttributeUnquotedEndSlash() throws {
//        let parser = HTMLTokenParser.tagAttribute
//        var text = Substring("custom = foo/")
//        XCTAssertThrowsError(try parser.parse(&text))
//    }
}
