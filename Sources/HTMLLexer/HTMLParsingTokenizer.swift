import Foundation
import Parsing

/// Namespace containing various parsers to map HTML elements to tokens according
/// to the [HTML specification](https://html.spec.whatwg.org/multipage/syntax.html).
enum HTMLTokenParser {
    static let byteOrderMark = Parse(input: Substring.self) {
        "\u{FEFF}"
    }.map { HTMLToken.byteOrderMark }

    static let comment = Parse(input: Substring.self) {
        "!--"
        PrefixUpTo("-->")
        "-->"
    }.map { (comment: Substring) in
        HTMLToken.comment(String(comment))
    }

    static let doctype = Parse(input: Substring.self) {
        "!"
        Prefix(7).filter { $0.lowercased() == "doctype" }
        Skip { oneOrMoreWhitespace }
        Prefix(4).filter { $0.lowercased() == "html" }
        Skip { CharacterSet.asciiWhitespace }
        Prefix { $0 != ">" }.map { $0.isEmpty ? nil : $0 }
        ">"
    }.map { (name: Substring, type: Substring, legacy: Substring?) in
        HTMLToken.doctype(
            name: String(name),
            type: String(type),
            legacy: legacy.map { String($0) }
        )
    }

    static let startTag = Parse(input: Substring.self) {
        tagName
        Optionally {
            Skip { oneOrMoreWhitespace }
            tagAttributes
        }.map { $0 ?? [HTMLToken.TagAttribute]() }
        Skip { CharacterSet.asciiWhitespace }
        Optionally { "/" }.map { $0 != nil }
        ">"
    }.map { (name: Substring, attributes: [HTMLToken.TagAttribute], isSelfClosing: Bool) in
        HTMLToken.tagStart(
            name: String(name),
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
        HTMLToken.tagEnd(name: String(name))
    }

    static let tagName = Prefix<Substring>(1...) {
        CharacterSet.asciiAlphanumerics.contains($0)
    }

    static let tagAttributeName = CharacterSet.htmlAttributeName.filter { !$0.isEmpty }

    static let tagAttributeValue = OneOf {
        Parse {
            "'"
            PrefixUpTo("'")
            "'"
        }
        Parse {
            "\""
            PrefixUpTo("\"")
            "\""
        }
        CharacterSet.htmlNonQuotedAttributeValue
            .filter { !$0.isEmpty && $0.last != "/" }
    }

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
        HTMLToken.TagAttribute(
            name: String(name),
            value: value.map { String($0) }
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

    static let oneOrMoreWhitespace = Prefix<Substring>(1...) {
        CharacterSet.asciiWhitespace.contains($0)
    }

    static let upToNextPotentialTag = Skip {
        PrefixUpTo("<")
    }
}

public struct HTMLLexerParsing {
    public static func parse(html: String) -> [HTMLToken] {
        var tokens = [HTMLToken]()
        var input = html[...]

        if let bom = try? HTMLTokenParser.byteOrderMark.parse(&input) {
            tokens.append(bom)
        }
        var textStartIndex = input.startIndex
        var textEndIndex = input.startIndex
        while !input.isEmpty {
            do {
                try HTMLTokenParser.upToNextPotentialTag.parse(&input)
            } catch {
                textEndIndex = html.endIndex
                break
            }
            if let tagToken = try? HTMLTokenParser.tag.parse(&input) {
                if textEndIndex > textStartIndex {
                    let text = String(html[textStartIndex..<textEndIndex])
                    tokens.append(.text(text))
                }
                tokens.append(tagToken)
                textStartIndex = input.startIndex
                textEndIndex = input.startIndex
            } else {
                // No tag found, treat everything parsed as text
                textEndIndex = input.startIndex
            }
        }
        if textEndIndex > textStartIndex {
            let text = String(html[textStartIndex..<textEndIndex])
            tokens.append(.text(text))
        }
        return tokens
    }
}
