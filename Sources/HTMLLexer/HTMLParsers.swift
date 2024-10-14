import Foundation
import Parsing

enum HTMLTagError: Error {
    case attributeNonQuotedValueMissingEndWhitespace
}

/// [HTML optional byte order mark](https://html.spec.whatwg.org/multipage/syntax.html#writing)
struct ByteOrderMark: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken?> {
        Optionally {
            "\u{FEFF}".utf8.map { HTMLToken.byteOrderMark }
        }
    }
}

/// [HTML CDATA](https://html.spec.whatwg.org/multipage/syntax.html#cdata-sections)
struct CData: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken> {
        Parse {
            "[CDATA[".utf8
            PrefixThrough("]]>".utf8)
        }.map {
            HTMLToken.cdata(Substring($0.dropLast(3)))
        }
    }
}

/// [HTML comment](https://html.spec.whatwg.org/multipage/syntax.html#comments)
struct Comment: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken> {
        Parse {
            "--".utf8
            PrefixThrough("-->".utf8)
        }.map {
            HTMLToken.comment(Substring($0.dropLast(3)))
        }
    }
}

/// [HTML DOCTYPE](https://html.spec.whatwg.org/multipage/syntax.html#the-doctype)
struct DocType: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken> {
        Parse {
            Prefix(7).filter { Substring($0).uppercased() == "DOCTYPE" }
            SkipASCIIWhitespace(min: 1)
            Prefix(4).filter { Substring($0).lowercased() == "html" }
            SkipASCIIWhitespace()
            PrefixThrough(">".utf8).map {
                let legacy = $0.dropLast().dropLast { CharacterSet.asciiWhitespace.contains(Unicode.Scalar($0)) }
                return legacy.isEmpty ? nil : legacy
            }
        }.map { name, type, legacy in
            HTMLToken.doctype(
                name: Substring(name),
                type: Substring(type),
                legacy: legacy.map { Substring($0) }
            )
        }
    }
}

/// [HTML elements](https://html.spec.whatwg.org/multipage/syntax.html#elements-2)
struct Tag: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken> {
        Backtracking {
            OneOf {
                StartTag()
                EndTag()
                Parse {
                    "!".utf8
                    OneOf {
                        Comment()
                        CData()
                        DocType()
                    }
                }
            }
        }
    }
}

/// [HTML start tag](https://html.spec.whatwg.org/multipage/syntax.html#start-tags)
struct StartTag: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken> {
        Parse {
            TagName()
            Optionally {
                SkipASCIIWhitespace(min: 1)
                TagAttributes()
            }.map { $0 ?? [HTMLToken.TagAttribute]() }
            SkipASCIIWhitespace()
            Optionally { "/".utf8 }.map { $0 != nil }
            ">".utf8
        }.map { name, attributes, isSelfClosing in
            HTMLToken.tagStart(
                name: Substring(name),
                attributes: attributes,
                isSelfClosing: isSelfClosing
            )
        }
    }
}

/// [HTML end tag](https://html.spec.whatwg.org/multipage/syntax.html#end-tags)
struct EndTag: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken> {
        Parse {
            "/".utf8
            TagName()
            SkipASCIIWhitespace()
            ">".utf8
        }.map { name in
            HTMLToken.tagEnd(name: Substring(name))
        }
    }
}

/// [HTML tag name](https://html.spec.whatwg.org/multipage/syntax.html#syntax-tag-name)
struct TagName: Parser {
    var body: some Parser<Substring.UTF8View, Substring.UTF8View> {
        Prefix(1...) {
            CharacterSet.asciiAlphanumerics.contains(Unicode.Scalar($0))
        }
    }
}

/// [HTML tag attribute](https://html.spec.whatwg.org/multipage/syntax.html#attributes-2)
struct TagAttribute: Parser {
    var body: some Parser<Substring.UTF8View, HTMLToken.TagAttribute> {
        Parse {
            TagAttributeName()
            SkipASCIIWhitespace()
            TagAttributeValue()
            SkipASCIIWhitespace()
        }.map { name, value in
            HTMLToken.TagAttribute(
                name: Substring(name),
                value: value.map { Substring($0) }
            )
        }
    }
}

/// Parses multiple tag attributes.
struct TagAttributes: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> [HTMLToken.TagAttribute] {
        var attributes = [HTMLToken.TagAttribute]()
        while let first = input.first {
            if first == UInt8(ascii: ">") || first == UInt8(ascii: "/") {
                break
            }
            let attribute = try TagAttribute().parse(&input)
            attributes.append(attribute)
        }
        return attributes
    }
}

/// [HTML attribute name](https://html.spec.whatwg.org/multipage/syntax.html#syntax-attribute-name)
struct TagAttributeName: Parser {
    var body: some Parser<Substring.UTF8View, Substring.UTF8View> {
        Prefix(1...) {
            CharacterSet.htmlAttributeName.contains(Unicode.Scalar($0))
        }
    }
}

/// [HTML attribute value](https://html.spec.whatwg.org/multipage/syntax.html#syntax-attribute-value)
struct TagAttributeValue: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> Substring.UTF8View? {
        guard input.first == UInt8(ascii: "=") else {
            return nil
        }
        input = input.dropFirst()
        try SkipASCIIWhitespace().parse(&input)
        let value: Substring.UTF8View
        switch input.first {
        case UInt8(ascii: "'"):
            value = try TagAttributeSingleQuotedValue().parse(&input)
        case UInt8(ascii: "\""):
            value = try TagAttributeDoubleQuotedValue().parse(&input)
        default:
            value = try TagAttributeNonQuotedValue().parse(&input)
        }
        return value
    }
}

/// [HTML non-quoted attribute value](https://html.spec.whatwg.org/multipage/syntax.html#attributes-2)
struct TagAttributeNonQuotedValue: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> Substring.UTF8View {
        let value = try Prefix(1...) {
            CharacterSet.htmlNonQuotedAttributeValue.contains(Unicode.Scalar($0))
        }.parse(&input)
        // Solidus `/` is allowed in non-quoted value so if tag is self-closing the value must be
        // followed by whitespace.
        if value.last == UInt8(ascii: "/"), input.first == UInt8(ascii: ">") {
            throw HTMLTagError.attributeNonQuotedValueMissingEndWhitespace
        }
        return value
    }
}

/// [HTML single-quoted attribute value](https://html.spec.whatwg.org/multipage/syntax.html#attributes-2)
struct TagAttributeSingleQuotedValue: Parser {
    var body: some Parser<Substring.UTF8View, Substring.UTF8View> {
        Parse {
            "'".utf8
            PrefixThrough("'".utf8)
        }.map { $0.dropLast() }
    }
}

/// [HTML double-quoted attribute value](https://html.spec.whatwg.org/multipage/syntax.html#attributes-2)
struct TagAttributeDoubleQuotedValue: Parser {
    var body: some Parser<Substring.UTF8View, Substring.UTF8View> {
        Parse {
            "\"".utf8
            PrefixThrough("\"".utf8)
        }.map { $0.dropLast() }
    }
}

// MARK: - Helpers

/// Skips a minimum number of ASCII whitespace. Default is 0.
struct SkipASCIIWhitespace: Parser {
    let min: Int

    init(min: Int = 0) {
        self.min = min
    }

    var body: some Parser<Substring.UTF8View, Void> {
        Skip {
            Prefix(min...) {
                CharacterSet.asciiWhitespace.contains(Unicode.Scalar($0))
            }
        }
    }
}

/// Parses HTML tokens from a UTF-8 view of a string.
struct Tokens: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> [HTMLToken] {
        var tokens = [HTMLToken]()
        if let bom = try ByteOrderMark().parse(&input) {
            tokens.append(bom)
        }

        let tagParser = Tag()
        let tagStartMarker = UInt8(ascii: "<")
        let html = input[...]
        var text = input[...]

        while let possibleTagIndex = input.firstIndex(of: tagStartMarker) {
            input = html[possibleTagIndex...].dropFirst()
            if let tagToken = try? tagParser.parse(&input) {
                text = html[text.startIndex..<possibleTagIndex]
                if !text.isEmpty {
                    tokens.append(.text(Substring(text)))
                }
                tokens.append(tagToken)
                text = html[input.startIndex...]
            }
        }

        if !text.isEmpty {
            tokens.append(.text(Substring(text)))
        }
        return tokens
    }
}
