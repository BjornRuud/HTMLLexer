import CollectionScanner
import Foundation

public struct HTMLTokenizer: Sequence, IteratorProtocol {
    public typealias Element = HTMLToken

    private let scanner: CollectionScanner<String>

    private var shouldParseBom: Bool = true

    private var textStart: String.Index

    private var textEnd: String.Index

    public init(html: String) {
        self.scanner = CollectionScanner(html)
        self.textStart = html.startIndex
        self.textEnd = html.startIndex
    }

    public mutating func next() -> HTMLToken? {
        if let queuedToken {
            self.queuedToken = nil
            return queuedToken
        }
        if shouldParseBom {
            shouldParseBom = false
            if let token = scanByteOrderMark() {
                textStart = scanner.currentIndex
                return token
            }
        }
        return tagAndTextParser()
    }

    private var queuedToken: HTMLToken?

    private mutating func tagAndTextParser() -> HTMLToken? {
        while !scanner.isAtEnd {
            scanner.skip { $0 != "<" }
            textEnd = scanner.currentIndex
            if let token = scanTag() {
                if textStart == textEnd {
                    textStart = scanner.currentIndex
                    return token
                }
                queuedToken = token
                return accumulatedTextToken()
            }
        }
        textEnd = scanner.currentIndex
        return accumulatedTextToken()
    }

    private mutating func accumulatedTextToken() -> HTMLToken? {
        if textStart == textEnd { return nil }
        let token: HTMLToken = .text(String(scanner.collection[textStart..<textEnd]))
        textStart = scanner.currentIndex
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
        let char = scanner.currentElement
        scanner.skip(1)
        return char
    }

    private func scanCharacter(_ character: Character) -> Bool {
        guard let foundCharacter = scanCharacter() else { return false }
        return character == foundCharacter
    }

    private func scanCaseInsensitiveCharacter(_ character: Character) -> Bool {
        guard let foundCharacter = scanCharacter() else { return false }
        return character.lowercased() == foundCharacter.lowercased()
    }

    private func scanCaseInsensitiveString(_ string: String) -> String.SubSequence? {
        let startIndex = scanner.currentIndex
        for character in string {
            guard
                let nextChar = scanCharacter(),
                character.lowercased() == nextChar.lowercased()
            else { return nil }
        }
        if scanner.currentIndex == startIndex {
            return nil
        }
        return scanner.collection[startIndex..<scanner.currentIndex]
    }

    private func scanString(_ string: String) -> Bool {
        for character in string {
            guard
                let foundChar = scanCharacter(),
                foundChar == character
            else { return false }
        }
        return true
    }

    private func scanUpToString(_ string: String) -> String.SubSequence? {
        let prefix = scanner.scan(upToCollection: string)
        return prefix.isEmpty ? nil : prefix
    }

    @discardableResult
    private func skip(minimum: Int, while predicate: (String.Element) -> Bool) -> Bool {
        var count = 0
        scanner.skip {
            if predicate($0) {
                count += 1
                return true
            }
            return false
        }
        return count >= minimum
    }

    @discardableResult
    private func skipOneOrMore(_ predicate: (String.Element) -> Bool) -> Bool {
        return skip(minimum: 1, while: predicate)
    }

    @discardableResult
    private func skipZeroOrMore(_ predicate: (String.Element) -> Bool) -> Bool {
        scanner.skip(while: predicate)
        return true
    }

    // MARK: - Scan functions

    private func scanByteOrderMark() -> HTMLToken? {
        guard scanner.currentElement == "\u{FEFF}" else {
            return nil
        }
        scanner.skip(1)
        return .byteOrderMark
    }

    private func scanTag() -> HTMLToken? {
        guard
            scanCharacter("<"),
            let nextCharacter = currentCharacter
        else { return nil }
        if nextCharacter == "!" {
            return scanMetaTag()
        } else if nextCharacter == "/" {
            return scanEndTag()
        }
        return scanBeginTag()
    }

    private func scanMetaTag() -> HTMLToken? {
        let potentialTagIndex = currentIndex
        if let commentTag = scanCommentTag() {
            return commentTag
        } else {
            scanner.setIndex(potentialTagIndex)
            return scanDoctypeTag()
        }
    }

    private func scanCommentTag() -> HTMLToken? {
        let endMarker = "-->"
        guard
            scanString("!--"),
            let comment = scanUpToString(endMarker),
            scanString(endMarker)
        else { return nil }
        return .comment(String(comment))
    }

    private func scanDoctypeTag() -> HTMLToken? {
        guard
            scanCharacter("!"),
            let name = scanCaseInsensitiveString("DOCTYPE"),
            skipOneOrMore({ isAsciiWhitespace($0) }),
            let type = scanCaseInsensitiveString("html"),
            skipZeroOrMore({ isAsciiWhitespace($0) }),
            let nextChar = peekCharacter()
        else { return nil }
        if nextChar == ">" {
            scanner.skip(1)
            return .doctype(name: String(name), type: String(type), legacy: nil)
        }
        let legacyText = scanner.scan(upTo: ">")
        guard scanCharacter(">") else { return nil }
        return .doctype(name: String(name), type: String(type), legacy: String(legacyText))
    }

    private func scanBeginTag() -> HTMLToken? {
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
            let name = scanTagName(),
            let currentChar = currentCharacter
        else { return nil }
        if isEndOfTag(currentChar) {
            var isSelfClosing = false
            guard scanEndOfTag(isSelfClosing: &isSelfClosing) else { return nil }
            return .tagStart(name: name, attributes: [], isSelfClosing: isSelfClosing)
        } else if isAsciiWhitespace(currentChar) {
            skipOneOrMore({ isAsciiWhitespace($0) })
        } else {
            return nil
        }

        let attributes = scanTagAttributes()
        var isSelfClosing = false
        guard scanEndOfTag(isSelfClosing: &isSelfClosing) else { return nil }
        return .tagStart(name: name, attributes: attributes, isSelfClosing: isSelfClosing)
    }

    private func scanEndTag() -> HTMLToken? {
        // https://html.spec.whatwg.org/multipage/syntax.html#end-tags
        guard
            scanCharacter("/"),
            let name = scanTagName(),
            skipZeroOrMore({ isAsciiWhitespace($0) }),
            scanCharacter(">")
        else { return nil }
        return .tagEnd(name: name)
    }

    private func scanTagName() -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-tag-name
        let name = scanner.scan(while: { CharacterSet.asciiAlphanumerics.contains($0) })
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributes() -> [HTMLToken.TagAttribute] {
        // https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
        var attributes: [HTMLToken.TagAttribute] = []
        while let nextChar = peekCharacter(), !isEndOfTag(nextChar) {
            guard let tagAttribute = scanTagAttribute() else {
                skipZeroOrMore({ isAsciiWhitespace($0) })
                continue
            }
            attributes.append(tagAttribute)
            skipZeroOrMore({ isAsciiWhitespace($0) })
        }
        return attributes
    }

    private func scanTagAttribute() -> HTMLToken.TagAttribute? {
        // Attributes have several variants:
        // name
        // name \s* = \s* value
        // name \s* = \s* 'value'
        // name \s* = \s* "value"
        guard
            let name = scanTagAttributeName(),
            skipZeroOrMore({ isAsciiWhitespace($0) }),
            let nextChar = peekCharacter()
        else { return nil }
        if isEndOfTag(nextChar) || nextChar != "=" {
            return .init(name: name, value: nil)
        }
        guard
            scanCharacter("="),
            skipZeroOrMore({ isAsciiWhitespace($0) }),
            let nextChar = peekCharacter()
        else { return nil }
        if isEndOfTag(nextChar) {
            return .init(name: name, value: nil)
        }
        guard let value = scanTagAttributeValue()
        else { return nil }
        return .init(name: name, value: value)
    }

    private func scanTagAttributeName() -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-attribute-name
        let name = scanner.scan(while: { CharacterSet.htmlAttributeName.contains($0) })
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributeValue() -> String? {
        guard let nextChar = scanner.currentElement else { return nil }
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
        // TODO: Spec compliant value
        let value = scanner.scan(upTo: quote)
        guard scanCharacter(quote)
        else { return nil }
        return String(value)
    }

    private func scanTagAttributeUnquotedValue() -> String? {
        let value = scanner.scan(while: { CharacterSet.htmlNonQuotedAttributeValue.contains($0) })
        return value.isEmpty ? nil : String(value)
    }
}
