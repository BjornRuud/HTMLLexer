import Foundation

public protocol HTMLLexerDelegate: AnyObject {
    func lexer(_ lexer: HTMLLexer, didFindToken token: HTMLLexer.Token)
}

public final class HTMLLexer {
    public enum Token: Equatable {
        case beginTag(name: String, attributes: [String: String], isSelfClosing: Bool)
        case endTag(name: String)
        case text(String)
        case commentTag(String)
        case doctypeTag(type: String, legacy: String?)
    }

    public weak var delegate: HTMLLexerDelegate?

    private let scanner: Scanner

    public init(html: String) {
        let scanner = Scanner(string: html)
        scanner.charactersToBeSkipped = nil
        self.scanner = scanner
    }

    public func read() {
        var accumulatedText = ""
        var potentialTagIndex = scanner.currentIndex
        while !scanner.isAtEnd {
            let foundText = scanner.scanUpToString("<")
            if let foundText = foundText {
                accumulatedText.append(foundText)
            }
            if scanner.isAtEnd { break }
            potentialTagIndex = scanner.currentIndex
            if let token = scanTag() {
                emitText(&accumulatedText)
                emitToken(token)
            } else {
                // Not a tag, append text scanned while searching
                let foundText = scanner.string[potentialTagIndex..<scanner.currentIndex]
                accumulatedText.append(String(foundText))
            }
        }
        emitText(&accumulatedText)
    }

    private func emitText(_ text: inout String) {
        guard !text.isEmpty else { return }
        emitToken(.text(text))
        text.removeAll()
    }

    private func emitToken(_ token: Token) {
        delegate?.lexer(self, didFindToken: token)
    }

    private func scanTag() -> Token? {
        guard scanner.scanCharacter() == "<" else { return nil }
        let currentCharacter = scanner.currentCharacter
        if currentCharacter == "!" {
            return scanCommentTag() ?? scanDoctypeTag()
        } else if currentCharacter == "/" {
            return scanEndTag()
        }
        return scanBeginTag()
    }

    private func scanCommentTag() -> Token? {
        guard scanner.scanCharacter() == "!" else { return nil }
        guard scanner.scanString("--") != nil else { return nil }
        var token: Token?
        let endMarker = "-->"
        if let comment = scanner.scanUpToString(endMarker), !scanner.isAtEnd {
            token = .commentTag(comment)
            for _ in 0..<endMarker.count {
                _ = scanner.scanCharacter()
            }
        }
        return token
    }

    private func scanDoctypeTag() -> Token? {
        return nil
    }

    private func scanBeginTag() -> Token? {
        return nil
    }

    private func scanEndTag() -> Token? {
        return nil
    }

    private func scanTagName() -> String? {
        return nil
    }

    private func scanTagAttributes() -> [String: String] {
        return [:]
    }
}

extension Scanner {
    var currentCharacter: Character? {
        guard !isAtEnd else { return nil }
        return string[currentIndex]
    }

    func peekCharacter(_ lookAhead: Int = 1) -> Character? {
        guard !isAtEnd else { return nil }
        var index = currentIndex
        for _ in 0 ..< lookAhead {
            index = string.index(after: index)
            guard index < string.endIndex else { return nil }
        }
        return string[index]
    }
}
