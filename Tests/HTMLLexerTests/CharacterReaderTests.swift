import XCTest
@testable import HTMLLexer

final class CharacterReaderTests: XCTestCase {
    func testConsume() throws {
        let reference = "abc"
        var reader = CharacterReader(input: reference)
        XCTAssertEqual(reference, String(reader.input[reader.readIndex..<reader.input.endIndex]))
        XCTAssertEqual(reader.consume(), "a")
        XCTAssertEqual("bc", String(reader.input[reader.readIndex..<reader.input.endIndex]))
    }

    func testConsumeUpTo() throws {
        let reference = "abc"
        var reader = CharacterReader(input: reference)
        XCTAssertEqual(reference, String(reader.input[reader.readIndex..<reader.input.endIndex]))
        XCTAssertEqual(reader.consume(upTo: "c"), "ab")
        XCTAssertEqual("c", String(reader.input[reader.readIndex..<reader.input.endIndex]))
    }

    func testConsumeWhile() throws {
        let reference = "abc"
        var reader = CharacterReader(input: reference)
        XCTAssertEqual(reference, String(reader.input[reader.readIndex..<reader.input.endIndex]))
        XCTAssertEqual(reader.consume(while: { $0 != "c" }), "ab")
        XCTAssertEqual("c", String(reader.input[reader.readIndex..<reader.input.endIndex]))
    }

    func testPeek() throws {
        let reference = "abc"
        let reader = CharacterReader(input: reference)
        XCTAssertEqual(reference, String(reader.input[reader.readIndex..<reader.input.endIndex]))
        XCTAssertEqual(reader.peek(), "a")
        XCTAssertEqual(reference, String(reader.input[reader.readIndex..<reader.input.endIndex]))
    }

    func testSetReadIndex() throws {
        let reference = "abc"
        var reader = CharacterReader(input: reference)
        XCTAssertEqual(reader.peek(), "a")
        reader.setReadIndex(reader.input.index(after: reader.readIndex))
        XCTAssertEqual(reader.peek(), "b")
    }

    func testSkipCount() throws {
        let reference = "abc"
        var reader = CharacterReader(input: reference)
        XCTAssertEqual(reader.peek(), "a")
        reader.skip(2)
        XCTAssertEqual(reader.peek(), "c")
    }

    func testSkipWhile() throws {
        let reference = "abc"
        var reader = CharacterReader(input: reference)
        XCTAssertEqual(reader.peek(), "a")
        reader.skip(while: { $0 == "a" || $0 == "b" })
        XCTAssertEqual(reader.peek(), "c")
    }
}
