import Foundation

public final class HTMLTokenizer<Input>: Sequence, IteratorProtocol
where Input: Collection, Input.Element == Character {
    public typealias Element = HTMLToken

    private var reader: CharacterReader<Input>

    private var textStart: Input.Index

    private var textEnd: Input.Index

    private var queuedToken: HTMLToken?

    public init(html: Input) {
        self.reader = CharacterReader(input: html)
        self.textStart = html.startIndex
        self.textEnd = html.startIndex

        self.queuedToken = scanByteOrderMark()
        if queuedToken != nil {
            textStart = reader.readIndex
        }
    }

    public func next() -> HTMLToken? {
        if let queuedToken {
            self.queuedToken = nil
            return queuedToken
        }
        return tagAndTextParser()
    }

    private func tagAndTextParser() -> HTMLToken? {
        while !reader.isAtEnd {
            reader.skip { $0 != "<" }
            textEnd = reader.readIndex
            if let tagToken = scanTag() {
                if let textToken = accumulatedTextToken() {
                    queuedToken = tagToken
                    return textToken
                }
                textStart = reader.readIndex
                return tagToken
            }
        }
        textEnd = reader.readIndex
        return accumulatedTextToken()
    }

    private func accumulatedTextToken() -> HTMLToken? {
        if textStart == textEnd { return nil }
        let token: HTMLToken = .text(String(reader.input[textStart..<textEnd]))
        textStart = reader.readIndex
        return token
    }

    // MARK: - Reader helper functions

    private func isEndOfTag(_ character: Character) -> Bool {
        return character == ">" || character == "/"
    }

    private func scanCharacter(_ character: Character) -> Bool {
        return character == reader.consume()
    }

    private func scanCaseInsensitiveString(_ string: String) -> Input.SubSequence? {
        let startIndex = reader.readIndex
        for character in string {
            guard character.lowercased() == reader.consume()?.lowercased()
            else { return nil }
        }
        if reader.readIndex == startIndex {
            return nil
        }
        return reader.input[startIndex..<reader.readIndex]
    }

    private func scanString(_ string: String) -> Bool {
        for character in string {
            guard character == reader.consume()
            else { return false }
        }
        return true
    }

    private func scanUpToString(
        _ string: String,
        consumeMarker: Bool = true
    ) -> Input.SubSequence? {
        guard let firstChar = string.first
        else { return nil }
        let consumeStart = reader.readIndex
        readerLoop: while !reader.isAtEnd {
            reader.skip { $0 != firstChar }
            let foundStart = reader.readIndex
            for character in string {
                if character != reader.consume() {
                    continue readerLoop
                }
            }
            if !consumeMarker {
                reader.setReadIndex(foundStart)
            }
            return reader.input[consumeStart..<foundStart]
        }
        return nil
    }

    @discardableResult
    private func skip(minimum: Int, while predicate: (Input.Element) -> Bool) -> Bool {
        var count = 0
        reader.skip {
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
        reader.skip(while: predicate)
        return true
    }

    // MARK: - Scan functions

    private func scanByteOrderMark() -> HTMLToken? {
        guard reader.peek() == "\u{FEFF}" else {
            return nil
        }
        reader.skip(1)
        return .byteOrderMark
    }

    private func scanTag() -> HTMLToken? {
        guard
            scanCharacter("<"),
            let nextCharacter = reader.peek()
        else { return nil }
        if nextCharacter == "/" {
            return scanEndTag()
        } else if nextCharacter == "!" {
            return scanMetaTag()
        }
        return scanBeginTag()
    }

    private func scanMetaTag() -> HTMLToken? {
        let potentialTagIndex = reader.readIndex
        if let commentTag = scanCommentTag() {
            return commentTag
        } else {
            reader.setReadIndex(potentialTagIndex)
            return scanDoctypeTag()
        }
    }

    private func scanCommentTag() -> HTMLToken? {
        guard
            scanString("!--"),
            let comment = scanUpToString("-->")
        else { return nil }
        return .comment(String(comment))
    }

    private func scanDoctypeTag() -> HTMLToken? {
        guard
            scanCharacter("!"),
            let name = scanCaseInsensitiveString("DOCTYPE"),
            skipOneOrMore({ CharacterSet.asciiWhitespace.contains($0) }),
            let type = scanCaseInsensitiveString("html"),
            skipZeroOrMore({ CharacterSet.asciiWhitespace.contains($0) }),
            let nextChar = reader.peek()
        else { return nil }
        if nextChar == ">" {
            reader.skip(1)
            return .doctype(name: String(name), type: String(type), legacy: nil)
        }
        let legacyText = reader.consume(upTo: ">")
        guard scanCharacter(">") else { return nil }
        return .doctype(name: String(name), type: String(type), legacy: String(legacyText))
    }

    private func scanBeginTag() -> HTMLToken? {
        // https://html.spec.whatwg.org/multipage/syntax.html#start-tags

        func scanEndOfTag(isSelfClosing: inout Bool) -> Bool {
            var character = reader.consume()
            if character == "/" {
                isSelfClosing = true
                character = reader.consume()
            } else {
                isSelfClosing = false
            }
            return character == ">"
        }

        guard
            let name = scanTagName(),
            let currentChar = reader.peek()
        else { return nil }
        if isEndOfTag(currentChar) {
            var isSelfClosing = false
            guard scanEndOfTag(isSelfClosing: &isSelfClosing) else { return nil }
            return .tagStart(name: name, attributes: [], isSelfClosing: isSelfClosing)
        } else if CharacterSet.asciiWhitespace.contains(currentChar) {
            skipOneOrMore({ CharacterSet.asciiWhitespace.contains($0) })
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
            skipZeroOrMore({ CharacterSet.asciiWhitespace.contains($0) }),
            scanCharacter(">")
        else { return nil }
        return .tagEnd(name: name)
    }

    private func scanTagName() -> String? {
        // https://html.spec.whatwg.org/multipage/syntax.html#syntax-tag-name
        let name = reader.consume(while: { CharacterSet.asciiAlphanumerics.contains($0) })
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributes() -> [HTMLToken.TagAttribute] {
        // https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
        var attributes: [HTMLToken.TagAttribute] = []
        while let nextChar = reader.peek(), !isEndOfTag(nextChar) {
            guard let tagAttribute = scanTagAttribute() else {
                skipZeroOrMore({ CharacterSet.asciiWhitespace.contains($0) })
                continue
            }
            attributes.append(tagAttribute)
            skipZeroOrMore({ CharacterSet.asciiWhitespace.contains($0) })
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
            skipZeroOrMore({ CharacterSet.asciiWhitespace.contains($0) }),
            let nextChar = reader.peek()
        else { return nil }
        if isEndOfTag(nextChar) || nextChar != "=" {
            return .init(name: name, value: nil)
        }
        guard
            scanCharacter("="),
            skipZeroOrMore({ CharacterSet.asciiWhitespace.contains($0) }),
            let nextChar = reader.peek()
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
        let name = reader.consume(while: { CharacterSet.htmlAttributeName.contains($0) })
        return name.isEmpty ? nil : String(name)
    }

    private func scanTagAttributeValue() -> String? {
        guard let nextChar = reader.peek() else { return nil }
        if nextChar == "\"" || nextChar == "'" {
            return scanTagAttributeQuotedValue()
        }
        return scanTagAttributeUnquotedValue()
    }

    private func scanTagAttributeQuotedValue() -> String? {
        guard
            let quote = reader.consume(),
            quote == "\"" || quote == "'"
        else { return nil }
        // TODO: Spec compliant value
        let value = reader.consume(upTo: quote)
        guard scanCharacter(quote)
        else { return nil }
        return String(value)
    }

    private func scanTagAttributeUnquotedValue() -> String? {
        let value = reader.consume(while: { CharacterSet.htmlNonQuotedAttributeValue.contains($0) })
        return value.isEmpty ? nil : String(value)
    }
}
