import Foundation
import Parsing

public enum HTMLToken: Equatable {
    case byteOrderMark
    case comment(Substring)
    case doctype(name: Substring, type: Substring, legacy: Substring?)
    case tagStart(name: Substring, attributes: [TagAttribute], isSelfClosing: Bool)
    case tagEnd(name: Substring)
    case text(Substring)
}

extension HTMLToken {
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
        Peek { "\u{FEFF}" }
        Prefix(1)
    }.map { _ in HTMLToken.byteOrderMark }

    static let comment = Backtracking {
        "<!--"
        PrefixUpTo("-->")
        "-->"
    }.map(HTMLToken.comment)

    static let doctype = Backtracking {
        "<!"
        Prefix(7).filter { $0.lowercased() == "doctype" }
        Skip { oneOrMoreWhitespace }
        Prefix(4).filter { $0.lowercased() == "html" }
        Skip { CharacterSet.asciiWhitespace }
        Prefix { $0 != ">" }.map { $0.isEmpty ? nil : $0 }
        ">"
    }.map(HTMLToken.doctype(name:type:legacy:))

    static let startTag = Backtracking {
        "<"
        tagName
        Optionally {
            Skip { oneOrMoreWhitespace }
            tagAttributes
        }.map { $0 ?? [HTMLToken.TagAttribute]() }
        Skip { CharacterSet.asciiWhitespace }
        Optionally { "/" }.map { $0 != nil }
        ">"
    }.map(HTMLToken.tagStart(name:attributes:isSelfClosing:))

    static let endTag = Backtracking {
        "</"
        tagName
        Skip { CharacterSet.asciiWhitespace }
        ">"
    }.map(HTMLToken.tagEnd(name:))

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
    }.map(HTMLToken.TagAttribute.init(name:value:))

    static let tagAttributes = Many {
        tagAttribute
    } terminator: {
        OneOf {
            Peek { ">" }
            Peek { "/" }
            End()
        }
    }

    static let tag = OneOf {
        startTag
        endTag
        comment
        doctype
    }

    // Helpers

    static let oneOrMoreWhitespace = Prefix<Substring>(1...) {
        CharacterSet.asciiWhitespace.contains($0)
    }
}

public struct HTMLParsingTokenizer: Sequence, IteratorProtocol {
    public typealias Element = HTMLLexer.Token

    public init(html: String) {
    }

    public mutating func next() -> HTMLLexer.Token? {
        return nil
    }

    public static func parse(_ input: inout Substring) throws -> [HTMLToken] {
        var tokens = [HTMLToken]()
        if let bom = try? HTMLTokenParser.byteOrderMark.parse(&input) {
            tokens.append(bom)
        }
        var foundText: Substring = ""
        while !input.isEmpty {
            if let foundPrefix = try? PrefixUpTo("<").parse(&input) {
                foundText += foundPrefix
            }
            if let tagToken = try? HTMLTokenParser.tag.parse(&input) {
                if !foundText.isEmpty {
                    tokens.append(.text(foundText))
                }
                foundText = ""
                tokens.append(tagToken)
            } else {
                // No tag found, skip tag start we tried from
                foundText += input.prefix(1)
                input = input.dropFirst()
            }
        }
        if !foundText.isEmpty {
            tokens.append(.text(foundText))
        }
        return tokens
    }
}

public struct HTMLLexerParsing {
    public static func parse(html: String) -> [HTMLToken] {
        var input = html[...]
        return (try? HTMLParsingTokenizer.parse(&input)) ?? []
    }
}
