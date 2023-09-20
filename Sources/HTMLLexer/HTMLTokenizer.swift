import CollectionScanner
import Foundation

public struct HTMLTokenizer: Sequence, IteratorProtocol {
    public typealias Element = HTMLLexer.Token

    private let scanner: CollectionScanner<String>

    public init(html: String) {
        self.scanner = CollectionScanner(html)
    }

    public mutating func next() -> HTMLLexer.Token? {
        if let queuedToken {
            self.queuedToken = nil
            return queuedToken
        }
        if shouldParseBom {
            shouldParseBom = false
            if let token = bomParser() {
                return token
            }
        }
        return tagAndTextParser()
    }

    private var shouldParseBom: Bool = true

    private func bomParser() -> HTMLLexer.Token? {
        guard scanner.peek() == "\u{FEFF}" else {
            return nil
        }
        scanner.advanceIndex()
        return .byteOrderMark
    }

    private var accumulatedText: String = ""

    private var queuedToken: HTMLLexer.Token?

    private mutating func tagAndTextParser() -> HTMLLexer.Token? {
        while !scanner.isAtEnd {
            if let foundText = scanUpToString("<") {
                accumulatedText.append(String(foundText))
            }
            if scanner.isAtEnd { break }
            let potentialTagIndex = currentIndex
            if let token = scanTag() {
                if accumulatedText.isEmpty {
                    return token
                }
                queuedToken = token
                return accumulatedTextToken()
            } else {
                // Not a tag, append text scanned while searching
                let foundText = scanner.collection[potentialTagIndex..<currentIndex]
                accumulatedText.append(String(foundText))
            }
        }
        return accumulatedTextToken()
    }

    private mutating func accumulatedTextToken() -> HTMLLexer.Token? {
        if accumulatedText.isEmpty { return nil }
        let token: HTMLLexer.Token = .text(accumulatedText)
        accumulatedText.removeAll()
        return token
    }

    // MARK: - String and character identification

    private func isAsciiAlphanumeric(_ character: Character) -> Bool {
        return CharacterSet.asciiAlphanumerics.contains(character)
    }

    private func isAsciiWhitespace(_ character: Character) -> Bool {
        return CharacterSet.asciiWhitespace.contains(character)
    }

    private func isEndOfTag(_ character: Character) -> Bool {
        return character == ">" || character == "/"
    }

    // MARK: - Scan helper functions

    private var currentCharacter: Character? {
        return scanner.currentElement
    }

    private var currentIndex: String.Index {
        return scanner.currentIndex
    }

    private func peekCharacter(offset: Int = 0) -> Character? {
        if offset == 0 {
            return scanner.peek()
        }
        return scanner.peek(offset: offset)
    }

    private func peekCharacter(_ character: Character, offset: Int = 0) -> Bool {
        guard let foundCharacter = peekCharacter(offset: offset) else { return false }
        return character == foundCharacter
    }

    private func scanCharacter() -> Character? {
        return scanner.scan()
    }

    private func scanCharacter(_ character: Character) -> Bool {
        guard let foundCharacter = scanner.scan() else { return false }
        return character == foundCharacter
    }

    private func scanCaseInsensitiveCharacter(_ character: Character) -> Bool {
        guard let foundCharacter = scanner.scan() else { return false }
        return character.lowercased() == foundCharacter.lowercased()
    }

    private func scanString(_ string: String) -> Bool {
        return scanner.scan(collection: string)
    }

    private func scanUpToString(_ string: String) -> String.SubSequence? {
        return scanner.scanUpTo(collection: string)
    }

    @discardableResult
    private func skipAsciiWhitespace() -> Bool {
        while let currentChar = scanner.currentElement {
            guard isAsciiWhitespace(currentChar) else { break }
            scanner.advanceIndex()
        }
        return true
    }

    // MARK: - Scan functions

    private func scanTag() -> HTMLLexer.Token? {
        guard
            scanCharacter("<"),
            let nextCharacter = currentCharacter
        else { return nil }
        if nextCharacter == "!" {
            return scanCommentTag() ?? scanDoctypeTag()
        } else if nextCharacter == "/" {
            return scanEndTag()
        }
        return scanBeginTag()
    }

    private func scanCommentTag() -> HTMLLexer.Token? {
        let endMarker = "-->"
        guard
            scanString("!--"),
            let comment = scanUpToString(endMarker),
            scanString(endMarker)
        else { return nil }
        return .comment(String(comment))
    }

    private func scanDoctypeTag() -> HTMLLexer.Token? {
        guard
            scanCharacter("!"),
            scanCaseInsensitiveCharacter("D"),
            scanCaseInsensitiveCharacter("O"),
            scanCaseInsensitiveCharacter("C"),
            scanCaseInsensitiveCharacter("T"),
            scanCaseInsensitiveCharacter("Y"),
            scanCaseInsensitiveCharacter("P"),
            scanCaseInsensitiveCharacter("E"),
            skipAsciiWhitespace()
        else { return nil }
        let typeStartIndex = currentIndex
        guard
            scanCaseInsensitiveCharacter("h"),
            scanCaseInsensitiveCharacter("t"),
            scanCaseInsensitiveCharacter("m"),
            scanCaseInsensitiveCharacter("l")
        else { return nil }
        let type = scanner.collection[typeStartIndex..<currentIndex]
        guard
            skipAsciiWhitespace(),
            let nextChar = peekCharacter()
        else { return nil }
        if nextChar == ">" {
            _ = scanCharacter()
            return .doctype(type: String(type), legacy: nil)
        }
        guard let legacyText = scanUpToString(">") else { return nil }
        _ = scanCharacter()
        return .doctype(type: String(type), legacy: String(legacyText))
    }

    private func scanBeginTag() -> HTMLLexer.Token? {
        // https://html.spec.whatwg.org/multipage/syntax.html#start-tags

        func scanEndOfTag(isSelfClosing: inout Bool) -> Bool {
            var character = scanCharacter()
            if character == "/" {
                isSelfClosing = true
                character = scanCharacter()
            } else {
                isSelfClosing = false
            }
            return character == ">"
        }

        guard
            let name = scanTagName(isBeginTag: true),
            skipAsciiWhitespace(),
            let currentChar = currentCharacter
        else { return nil }
        if isEndOfTag(currentChar) {
            var isSelfClosing = false
            guard scanEndOfTag(isSelfClosing: &isSelfClosing) else { return nil }
            return .tagStart(name: name, attributes: [:], isSelfClosing: isSelfClosing)
        }

        var attributes: [String: String] = [:]
        if let foundAttributes = scanTagAttributes() {
            attributes = foundAttributes
        }
        var isSelfClosing = false
        guard scanEndOfTag(isSelfClosing: &isSelfClosing) else { return nil }
        return .tagStart(name: name, attributes: attributes, isSelfClosing: isSelfClosing)
    }

    private func scanEndTag() -> HTMLLexer.Token? {
        // https://html.spec.whatwg.org/multipage/syntax.html#end-tags
        guard
            scanCharacter("/"),
            let name = scanTagName(isBeginTag: false),
            skipAsciiWhitespace(),
            scanCharacter(">")
        else { return nil }
        return .tagEnd(name: name)
    }

    private func scanTagName(isBeginTag: Bool) -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-tag-name
        let nameStartIndex = scanner.currentIndex
        while let foundChar = scanCharacter() {
            guard
                isAsciiAlphanumeric(foundChar),
                let nextChar = peekCharacter()
            else { return nil }
            if isBeginTag {
                if nextChar == ">"
                    || nextChar == "/"
                    || isAsciiWhitespace(nextChar) {
                    break
                }
            } else {
                if nextChar == ">"
                    || isAsciiWhitespace(nextChar) {
                    break
                }
            }
        }
        let name = scanner.collection[nameStartIndex..<scanner.currentIndex]
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributes() -> [String: String]? {
        // https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
        var attributes: [String: String] = [:]
        while let nextChar = peekCharacter(), !isEndOfTag(nextChar) {
            guard let (name, value) = scanTagAttribute() else {
                skipAsciiWhitespace()
                continue
            }
            attributes[name] = value
            skipAsciiWhitespace()
        }
        return attributes
    }

    private func scanTagAttribute() -> (String, String)? {
        // Attributes have several variants:
        // name
        // name \s* =
        // name \s* = \s* value
        // name \s* = \s* 'value'
        // name \s* = \s* "value"
        guard
            let name = scanTagAttributeName(),
            skipAsciiWhitespace(),
            let nextChar = peekCharacter()
        else { return nil }
        if isEndOfTag(nextChar) || nextChar != "=" {
            return (name, "")
        }
        guard
            scanCharacter("="),
            skipAsciiWhitespace(),
            let nextChar = peekCharacter()
        else { return nil }
        if isEndOfTag(nextChar) {
            return (name, "")
        }
        guard let value = scanTagAttributeValue() else { return nil }
        return (name, value)
    }

    private func scanTagAttributeName() -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-attribute-name
        let nameStartIndex = currentIndex
        while true {
            guard
                let character = scanCharacter(),
                CharacterSet.htmlAttributeName.contains(character),
                let nextChar = peekCharacter()
            else { return nil }
            if nextChar == "=" || isAsciiWhitespace(nextChar) || isEndOfTag(nextChar) {
                break
            }
        }
        let name = scanner.collection[nameStartIndex..<scanner.currentIndex]
        return String(name)
    }

    private func scanTagAttributeValue() -> String? {
        guard let nextChar = peekCharacter() else { return nil }
        if nextChar == "\"" || nextChar == "'" {
            return scanTagAttributeQuotedValue()
        }
        return scanTagAttributeUnquotedValue()
    }

    private func scanTagAttributeQuotedValue() -> String? {
        guard
            let quote = scanCharacter(),
            quote == "\"" || quote == "'"
        else { return nil }
        guard
            let value = scanner.scanUpTo(quote),
            scanCharacter(quote)
        else { return nil }
        return String(value)
    }

    private func scanTagAttributeUnquotedValue() -> String? {
        let valueStartIndex = currentIndex
        while true {
            guard let nextChar = peekCharacter() else { return nil }
            if !CharacterSet.htmlNonQuotedAttributeValue.contains(nextChar) { break }
            guard scanCharacter() != nil else { return nil }
        }
        let value = scanner.collection[valueStartIndex..<scanner.currentIndex]
        return String(value)
    }
}
