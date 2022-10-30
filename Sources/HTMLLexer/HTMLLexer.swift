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
        // https://html.spec.whatwg.org/multipage/syntax.html#start-tags
        guard let name = scanTagName() else { return nil }
        let attributes = scanTagAttributes()
        var isSelfClosing = false
        while let character = scanner.scanCharacter() {
            if character == "/" {
                isSelfClosing = true
                if scanner.scanCharacter() == ">" { break }
                return nil
            } else if character == ">" {
                break
            }
        }
        return .beginTag(name: name, attributes: attributes, isSelfClosing: isSelfClosing)
    }

    private func scanEndTag() -> Token? {
        return nil
    }

    private func scanTagName() -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-tag-name
        let asciiAlphanumerics = CharacterSet.asciiAlphanumerics
        let asciiWhitespace = CharacterSet.asciiWhitespace
        let nameStartIndex = scanner.currentIndex
        while let foundChar = scanner.scanCharacter() {
            let foundScalars = foundChar.unicodeScalars
            guard
                foundScalars.count == 1,
                asciiAlphanumerics.contains(foundScalars[foundScalars.startIndex])
            else { return nil }
            guard let currentChar = scanner.currentCharacter else { return nil }
            let currentCharScalars = currentChar.unicodeScalars
            let currentScalar = currentCharScalars[currentCharScalars.startIndex]
            if currentChar == ">" || asciiWhitespace.contains(currentScalar) {
                break
            }
        }
        let name = scanner.string[nameStartIndex..<scanner.currentIndex]
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributes() -> [String: String] {
        return [:]
    }
}

extension CharacterSet {
    static var asciiAlphanumerics: CharacterSet = {
        // An ASCII digit is a code point in the range U+0030 (0) to U+0039 (9), inclusive.
        // An ASCII upper alpha is a code point in the range U+0041 (A) to U+005A (Z), inclusive.
        // An ASCII lower alpha is a code point in the range U+0061 (a) to U+007A (z), inclusive.
        var charSet = CharacterSet()
        let digitRange = Unicode.Scalar(48)...Unicode.Scalar(57)
        charSet.insert(charactersIn: digitRange)
        let upperAlphaRange = Unicode.Scalar(65)...Unicode.Scalar(90)
        charSet.insert(charactersIn: upperAlphaRange)
        let lowerAlphaRange = Unicode.Scalar(97)...Unicode.Scalar(122)
        charSet.insert(charactersIn: lowerAlphaRange)
        return charSet
    }()

    static var asciiWhitespace: CharacterSet = {
        // ASCII whitespace is U+0009 TAB, U+000A LF, U+000C FF, U+000D CR, or U+0020 SPACE.
        var charSet = CharacterSet()
        charSet.insert(Unicode.Scalar(9))
        charSet.insert(Unicode.Scalar(10))
        charSet.insert(Unicode.Scalar(12))
        charSet.insert(Unicode.Scalar(13))
        charSet.insert(Unicode.Scalar(32))
        return charSet
    }()
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
