import Foundation
@preconcurrency import Parsing

struct HTMLParsingError: Error {
    let message: String
}

public enum HTMLParsingToken: Equatable {
    case byteOrderMark
    case comment(Substring)
    case doctype(name: Substring, type: Substring, legacy: Substring?)
    case tagStart(name: Substring, attributes: [TagAttribute], isSelfClosing: Bool)
    case tagEnd(name: Substring)
    case text(Substring)
}

extension HTMLParsingToken {
    public struct TagAttribute: Equatable {
        public let name: Substring
        public let value: Substring?

        public init(name: Substring, value: Substring?) {
            self.name = name
            self.value = value
        }
    }
}

/// Namespace containing various parsers to map HTML elements to tokens according
/// to the [HTML specification](https://html.spec.whatwg.org/multipage/syntax.html).
enum HTMLTokenParser {
    static let byteOrderMark = Parse(input: Substring.self) {
        "\u{FEFF}"
    }.map { HTMLParsingToken.byteOrderMark }

    static let comment = Parse(input: Substring.self) {
        "!--"
        PrefixThrough("-->")
    }.map { (comment: Substring) in
        HTMLParsingToken.comment(comment.dropLast(3))
    }

    static let doctype = Parse(input: Substring.self) {
        "!"
        Prefix(7).filter { $0.uppercased() == "DOCTYPE" }
        SkipASCIIWhitespace(min: 1)
        Prefix(4).filter { $0.lowercased() == "html" }
        SkipASCIIWhitespace(min: 0)
        PrefixThrough(">").map {
            let legacy = $0.dropLast()
            return legacy.isEmpty ? nil : legacy
        }
    }.map { (name: Substring, type: Substring, legacy: Substring?) in
        HTMLParsingToken.doctype(
            name: name,
            type: type,
            legacy: legacy
        )
    }

    static let startTag = Parse(input: Substring.self) {
        tagName
        Optionally {
            SkipASCIIWhitespace(min: 1)
            tagAttributes
        }.map { $0 ?? [HTMLParsingToken.TagAttribute]() }
        Skip { CharacterSet.asciiWhitespace }
        Optionally { "/" }.map { $0 != nil }
        ">"
    }.map { (name: Substring, attributes: [HTMLParsingToken.TagAttribute], isSelfClosing: Bool) in
        HTMLParsingToken.tagStart(
            name: name,
            attributes: attributes,
            isSelfClosing: isSelfClosing
        )
    }

    static let endTag = Parse(input: Substring.self) {
        "/"
        tagName
        Skip { CharacterSet.asciiWhitespace }
        ">"
    }.map { (name: Substring) in
        HTMLParsingToken.tagEnd(name: name)
    }

    static let tagName = Prefix<Substring>(1...) {
        CharacterSet.asciiAlphanumerics.contains($0)
    }

    static let tagAttributeName = CharacterSet.htmlAttributeName.filter { !$0.isEmpty }

    static let tagAttributeValue = OneOf {
        tagAttributeSingleQuotedValue
        tagAttributeDoubleQuotedValue
        tagAttributeNonQuotedValue
    }

    static let tagAttributeNonQuotedValue = CharacterSet.htmlNonQuotedAttributeValue
        .filter { !$0.isEmpty && $0.last != "/" }

    static let tagAttributeSingleQuotedValue = Parse(input: Substring.self) {
        "'"
        PrefixThrough("'")
    }.map { $0.dropLast() }

    static let tagAttributeDoubleQuotedValue = Parse(input: Substring.self) {
        "\""
        PrefixThrough("\"")
    }.map { $0.dropLast() }

    static let tagAttribute = Parse(input: Substring.self) {
        tagAttributeName
        Optionally {
            Skip { CharacterSet.asciiWhitespace }
            "="
            Skip { CharacterSet.asciiWhitespace }
        }.flatMap {
            if $0 == nil {
                Always<Substring, Substring?>(nil)
            } else {
                tagAttributeValue
                    .map { Optional<Substring>($0) }
            }
        }
        Skip { CharacterSet.asciiWhitespace }
    }.map { (name: Substring, value: Substring?) in
        HTMLParsingToken.TagAttribute(
            name: name,
            value: value
        )
    }

    static let tagAttributes = Many {
        tagAttribute
    } terminator: {
        OneOf {
            Peek { ">" }
            Peek { "/" }
            End()
        }
    }

    static let tag = Parse(input: Substring.self) {
        "<"
        OneOf {
            startTag
            endTag
            comment
            doctype
        }
    }

    // Helpers

    struct SkipASCIIWhitespace: Parser {
        let min: Int

        func parse(_ input: inout Substring) throws {
            _ = try Prefix<Substring>(min...) {
                CharacterSet.asciiWhitespace.contains($0)
            }.parse(&input)
        }
    }
}

public struct HTMLLexerParsing {
    public func parse(html: Substring) throws -> [HTMLParsingToken] {
        var tokens = [HTMLParsingToken]()
        var input = html[...]
        var text = html[...]

        if let bom = try? HTMLTokenParser.byteOrderMark.parse(&input) {
            tokens.append(bom)
            text = text.dropFirst()
        }

        while !input.isEmpty {
            guard let possibleTagIndex = input.firstIndex(of: "<") else {
                text = html[text.startIndex...]
                break
            }

            input = html[possibleTagIndex...]
            if let tagToken = try? HTMLTokenParser.tag.parse(&input) {
                text = html[text.startIndex..<possibleTagIndex]
                if !text.isEmpty {
                    tokens.append(.text(text))
                }
                tokens.append(tagToken)
                text = html[input.startIndex...]
            } else {
                input = html[possibleTagIndex...].dropFirst()
            }
        }

        if !text.isEmpty {
            tokens.append(.text(text))
        }
        return tokens
    }

    public func parse(html: String) throws -> [HTMLParsingToken] {
        return try parse(html: html[...])
    }

    public static func parse(html: Substring) throws -> [HTMLParsingToken] {
        let parser = HTMLLexerParsing()
        return try parser.parse(html: html)
    }

    public static func parse(html: String) throws -> [HTMLParsingToken] {
        return try parse(html: html[...])
    }
}
