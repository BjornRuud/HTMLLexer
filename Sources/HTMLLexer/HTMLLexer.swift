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

    private func isAsciiAlphanumeric(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        guard scalars.count == 1 else { return false }
        let scalar = scalars[scalars.startIndex]
        return CharacterSet.asciiAlphanumerics.contains(scalar)
    }

    private func isAsciiWhitespace(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        guard scalars.count == 1 else { return false }
        let scalar = scalars[scalars.startIndex]
        return CharacterSet.asciiWhitespace.contains(scalar)
    }

    private var currentCharacter: Character? {
        return scanner.currentCharacter
    }

    private func nextCharacter(_ offset: Int = 1) -> Character? {
        return scanner.peekCharacter(offset)
    }

    private func scanCharacter() -> Character? {
        return scanner.scanCharacter()
    }

    private func scanTag() -> Token? {
        guard
            currentCharacter == "<",
            let nextCharacter = nextCharacter()
        else { return nil }
        if nextCharacter == "!" {
            return scanCommentTag() ?? scanDoctypeTag()
        } else if nextCharacter == "/" {
            return scanEndTag()
        }
        return scanBeginTag()
    }

    private func scanCommentTag() -> Token? {
        guard
            scanCharacter() == "<",
            scanCharacter() == "!",
            scanCharacter() == "-",
            scanCharacter() == "-"
        else { return nil }
        var token: Token?
        let endMarker = "-->"
        if let comment = scanner.scanUpToString(endMarker), !scanner.isAtEnd {
            token = .commentTag(comment)
            for _ in 0..<endMarker.count {
                _ = scanCharacter()
            }
        }
        return token
    }

    private func scanDoctypeTag() -> Token? {
        return nil
    }

    private func scanBeginTag() -> Token? {
        // https://html.spec.whatwg.org/multipage/syntax.html#start-tags
        guard
            scanCharacter() == "<",
            let name = scanTagName(),
            let currentChar = currentCharacter
        else { return nil }
        var attributes: [String: String] = [:]
        if isAsciiWhitespace(currentChar), let foundAttributes = scanTagAttributes() {
            attributes = foundAttributes
        }
        var isSelfClosing = false
        var character = scanCharacter()
        if character == "/" {
            isSelfClosing = true
            character = scanCharacter()
        }
        guard character == ">" else { return nil }
        return .beginTag(name: name, attributes: attributes, isSelfClosing: isSelfClosing)
    }

    private func scanEndTag() -> Token? {
        // https://html.spec.whatwg.org/multipage/syntax.html#end-tags
        guard
            scanCharacter() == "<",
            scanCharacter() == "/",
            let name = scanTagName(),
            skipAsciiWhitespace(),
            scanCharacter() == ">"
        else { return nil }
        return .endTag(name: name)
    }

    private func scanTagName() -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-tag-name
        let nameStartIndex = scanner.currentIndex
        while let foundChar = scanCharacter() {
            guard isAsciiAlphanumeric(foundChar) else { return nil }
            guard let currentChar = currentCharacter else { return nil }
            if currentChar == ">"
                || currentChar == "/"
                || isAsciiWhitespace(currentChar) {
                break
            }
        }
        let name = scanner.string[nameStartIndex..<scanner.currentIndex]
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributes() -> [String: String]? {
        // https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
        skipAsciiWhitespace()
        return [:]
    }

    @discardableResult
    private func skipAsciiWhitespace() -> Bool {
        repeat {
            guard
                let currentChar = currentCharacter,
                isAsciiWhitespace(currentChar)
            else { break }
        } while scanCharacter() != nil
        return true
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
