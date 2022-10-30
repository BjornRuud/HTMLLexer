import XCTest
@testable import HTMLLexer

final class HTMLLexerTests: XCTestCase {
    private final class TokenCollector: HTMLLexerDelegate {
        var tokens: [HTMLLexer.Token] = []

        func lexer(_ lexer: HTMLLexer, didFindToken token: HTMLLexer.Token) {
            tokens.append(token)
        }
    }

    private func lexer(html: String) -> HTMLLexer {
        let lexer = HTMLLexer(html: html)
        lexerDelegate.tokens.removeAll()
        lexer.delegate = lexerDelegate
        return lexer
    }

    private var lexerDelegate = TokenCollector()

    func testCommentTag() throws {
        let lexer = lexer(html: "<!-- Foo -->")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .commentTag(" Foo ")
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

    func testCommentNoEnd() throws {
        let lexer = lexer(html: "Asdf <!-- Foo")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .text("Asdf <!-- Foo")
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

    func testCommentDoubleEnd() throws {
        let lexer = lexer(html: "<!-- Foo -->-->")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .commentTag(" Foo "),
            .text("-->")
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

    func testBeginTag() throws {
        let lexer = lexer(html: "<b><b >")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .beginTag(name: "b", attributes: [:], isSelfClosing: false),
            .beginTag(name: "b", attributes: [:], isSelfClosing: false),
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

    func testBeginMalformedTag() throws {
        let lexer = lexer(html: "< b><b🎃 >")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .text("< b><b🎃 >")
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

    func testBeginSelfClosedTag() throws {
        let lexer = lexer(html: "<div/><div />")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .beginTag(name: "div", attributes: [:], isSelfClosing: true),
            .beginTag(name: "div", attributes: [:], isSelfClosing: true),
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

    func testBeginSelfClosedMalformedTag() throws {
        let lexer = lexer(html: "<div/ ><div / >")
        lexer.read()
        let reference: [HTMLLexer.Token] = [
            .text("<div/ ><div / >")
        ]
        XCTAssertEqual(lexerDelegate.tokens, reference)
    }

}
