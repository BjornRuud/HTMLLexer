import Foundation
import Parsing

/// Namespace containing various parsers to map HTML elements to tokens according
/// to the [HTML specification](https://html.spec.whatwg.org/multipage/syntax.html).
enum HTMLTokenParser {
    static let byteOrderMark = Parse(input: Substring.UnicodeScalarView.self) {
        "\u{FEFF}".unicodeScalars
    }.map {
        HTMLToken.byteOrderMark
    }

    static let comment = Parse(input: Substring.UnicodeScalarView.self) {
        "!--".unicodeScalars
        PrefixUpTo(Substring("-->").unicodeScalars)
        "-->".unicodeScalars
    }.map {
        HTMLToken.comment(String($0))
    }

    static let doctype = Parse(input: Substring.UnicodeScalarView.self) {
        "!".unicodeScalars
        Prefix(7).filter { Substring($0).lowercased() == "doctype" }
        Skip { oneOrMoreASCIIWhitespace }
        Prefix(4).filter { Substring($0).lowercased() == "html" }
        Skip { Prefix { CharacterSet.asciiWhitespace.contains($0) } }
        Prefix { $0 != ">" }.map { $0.isEmpty ? nil : $0 }
        ">".unicodeScalars
    }.map { (name: Substring.UnicodeScalarView, type: Substring.UnicodeScalarView, legacy: Substring.UnicodeScalarView?) in
        HTMLToken.doctype(
            name: String(name),
            type: String(type),
            legacy: legacy.map { String($0) }
        )
    }

    static let startTag = Parse(input: Substring.UnicodeScalarView.self) {
        tagName
        Optionally {
            Skip { oneOrMoreASCIIWhitespace }
            tagAttributes
        }.map { $0 ?? [HTMLToken.TagAttribute]() }
        Skip { zeroOrMoreASCIIWhitespace }
        Optionally { "/".unicodeScalars }.map { $0 != nil }
        ">".unicodeScalars
    }.map { (name: Substring.UnicodeScalarView, attributes: [HTMLToken.TagAttribute], isSelfClosing: Bool) in
        HTMLToken.tagStart(
            name: String(name),
            attributes: attributes,
            isSelfClosing: isSelfClosing
        )
    }

    static let endTag = Parse(input: Substring.UnicodeScalarView.self) {
        "/".unicodeScalars
        tagName
        Skip { zeroOrMoreASCIIWhitespace }
        ">".unicodeScalars
    }.map { (name: Substring.UnicodeScalarView) in
        HTMLToken.tagEnd(name: String(name))
    }

    static let tagName = Prefix<Substring.UnicodeScalarView>(1...) {
        CharacterSet.asciiAlphanumerics.contains($0)
    }

    static let tagAttributeName = Prefix<Substring.UnicodeScalarView>(1...) {
        CharacterSet.htmlAttributeName.contains($0)
    }

    static let tagAttributeValue = OneOf {
        Parse {
            "'".unicodeScalars
            PrefixUpTo(Substring("'").unicodeScalars)
            "'".unicodeScalars
        }
        Parse {
            "\"".unicodeScalars
            PrefixUpTo(Substring("\"").unicodeScalars)
            "\"".unicodeScalars
        }
        Prefix(1...) {
            CharacterSet.htmlNonQuotedAttributeValue.contains($0)
        }.filter {
            $0.last != "/"
        }
    }

    static let tagAttribute = Parse(input: Substring.UnicodeScalarView.self) {
        tagAttributeName
        Optionally {
            Skip { zeroOrMoreASCIIWhitespace }
            "=".unicodeScalars
            Skip { zeroOrMoreASCIIWhitespace }
        }.flatMap {
            if $0 == nil {
                Always<Substring.UnicodeScalarView, Substring.UnicodeScalarView?>(nil)
            } else {
                tagAttributeValue
                    .map { Optional<Substring.UnicodeScalarView>($0) }
            }
        }
        Skip { zeroOrMoreASCIIWhitespace }
    }.map { (name: Substring.UnicodeScalarView, value: Substring.UnicodeScalarView?) in
        HTMLToken.TagAttribute(
            name: String(name),
            value: value.map { String($0) }
        )
    }

    static let tagAttributes = Many {
        tagAttribute
    } terminator: {
        OneOf {
            Peek { ">".unicodeScalars }
            Peek { "/".unicodeScalars }
            End()
        }
    }

    static let tag = Parse(input: Substring.UnicodeScalarView.self) {
        "<".unicodeScalars
        OneOf {
            startTag
            endTag
            comment
            doctype
        }
    }

    // Helpers

    static let oneOrMoreASCIIWhitespace = Prefix<Substring.UnicodeScalarView>(1...) {
        CharacterSet.asciiWhitespace.contains($0)
    }

    static let zeroOrMoreASCIIWhitespace = Prefix<Substring.UnicodeScalarView>(0...) {
        CharacterSet.asciiWhitespace.contains($0)
    }
}

public struct HTMLLexerParsing {
    public static func parse(html: String) -> [HTMLToken] {
        var tokens = [HTMLToken]()
        var input = html[...].unicodeScalars

        if let bom = try? HTMLTokenParser.byteOrderMark.parse(&input) {
            tokens.append(bom)
        }
        var textStartIndex = input.startIndex
        var textEndIndex = input.startIndex
        while !input.isEmpty {
            if let possibleTagIndex = input.firstIndex(of: "<") {
                input = input[possibleTagIndex...]
            } else {
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
