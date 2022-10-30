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
}
