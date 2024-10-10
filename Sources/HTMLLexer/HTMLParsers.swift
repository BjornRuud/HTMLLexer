import Foundation
import Parsing

struct ByteOrderMark: Parser {
    var body: some Parser<Substring, HTMLParsingToken?> {
        Optionally {
            "\u{FEFF}".map { HTMLParsingToken.byteOrderMark }
        }
    }
}

struct Comment: Parser {
    var body: some Parser<Substring, HTMLParsingToken> {
        Parse {
            "!--"
            PrefixThrough("-->")
        }.map {
            HTMLParsingToken.comment($0.dropLast(3))
        }
    }
}

struct DocType: Parser {
    var body: some Parser<Substring, HTMLParsingToken> {
        Parse {
            "!"
            Prefix(7).filter { $0.uppercased() == "DOCTYPE" }
            SkipASCIIWhitespace(min: 1)
            Prefix(4).filter { $0.lowercased() == "html" }
            SkipASCIIWhitespace()
            PrefixThrough(">").map {
                let legacy = $0.dropLast()
                return legacy.isEmpty ? nil : legacy
            }
        }.map { name, type, legacy in
            HTMLParsingToken.doctype(
                name: name,
                type: type,
                legacy: legacy
            )
        }
    }
}

struct StartTag: Parser {
    var body: some Parser<Substring, HTMLParsingToken> {
        Parse {
            TagName()
            Optionally {
                SkipASCIIWhitespace(min: 1)
                TagAttributes()
            }.map { $0 ?? [HTMLParsingToken.TagAttribute]() }
            SkipASCIIWhitespace()
            Optionally { "/" }.map { $0 != nil }
            ">"
        }.map { name, attributes, isSelfClosing in
            HTMLParsingToken.tagStart(
                name: name,
                attributes: attributes,
                isSelfClosing: isSelfClosing
            )
        }
    }
}

struct EndTag: Parser {
    var body: some Parser<Substring, HTMLParsingToken> {
        Parse {
            "/"
            TagName()
            SkipASCIIWhitespace()
            ">"
        }.map { name in
            HTMLParsingToken.tagEnd(name: name)
        }
    }
}

struct TagName: Parser {
    var body: some Parser<Substring, Substring> {
        Prefix(1...) {
            CharacterSet.asciiAlphanumerics.contains($0)
        }
    }
}

struct TagAttributeName: Parser {
    var body: some Parser<Substring, Substring> {
        CharacterSet.htmlAttributeName.filter { !$0.isEmpty }
    }
}

struct TagAttributeValue: Parser {
    func parse(_ input: inout Substring) throws -> Substring? {
        guard input.first == "=" else {
            return nil
        }
        input = input.dropFirst()
        try SkipASCIIWhitespace().parse(&input)
        let value: Substring
        switch input.first {
        case "'":
            value = try TagAttributeSingleQuotedValue().parse(&input)
        case "\"":
            value = try TagAttributeDoubleQuotedValue().parse(&input)
        default:
            value = try TagAttributeNonQuotedValue().parse(&input)
        }
        return value
    }
}

struct TagAttributeNonQuotedValue: Parser {
    var body: some Parser<Substring, Substring> {
        CharacterSet.htmlNonQuotedAttributeValue
            .filter { !$0.isEmpty && $0.last != "/" }
    }
}

struct TagAttributeSingleQuotedValue: Parser {
    var body: some Parser<Substring, Substring> {
        Parse {
            "'"
            PrefixThrough("'")
        }.map { $0.dropLast() }
    }
}

struct TagAttributeDoubleQuotedValue: Parser {
    var body: some Parser<Substring, Substring> {
        Parse {
            "\""
            PrefixThrough("\"")
        }.map { $0.dropLast() }
    }
}

struct TagAttribute: Parser {
    var body: some Parser<Substring, HTMLParsingToken.TagAttribute> {
        Parse {
            TagAttributeName()
            SkipASCIIWhitespace()
            TagAttributeValue()
            SkipASCIIWhitespace()
        }.map { name, value in
            HTMLParsingToken.TagAttribute(
                name: name,
                value: value
            )
        }
    }
}

struct TagAttributes: Parser {
    func parse(_ input: inout Substring) throws -> [HTMLParsingToken.TagAttribute] {
        var attributes = [HTMLParsingToken.TagAttribute]()
        while let first = input.first {
            if first == ">" || first == "/" {
                break
            }
            let attribute = try TagAttribute().parse(&input)
            attributes.append(attribute)
        }
        return attributes
    }
}

struct Tag: Parser {
    var body: some Parser<Substring, HTMLParsingToken> {
        "<"
        OneOf {
            StartTag()
            EndTag()
            Comment()
            DocType()
        }
    }
}

// Helpers

struct SkipASCIIWhitespace: Parser {
    let min: Int

    init(min: Int = 0) {
        self.min = min
    }

    var body: some Parser<Substring, Void> {
        Skip {
            Prefix(min...) {
                CharacterSet.asciiWhitespace.contains($0)
            }
        }
    }
}

struct Document: Parser {
    func parse(_ input: inout Substring) throws -> [HTMLParsingToken] {
        var tokens = [HTMLParsingToken]()
        if let bom = try ByteOrderMark().parse(&input) {
            tokens.append(bom)
        }

        let tagParser = Tag()
        let html = input[...]
        var text = input[...]

        while !input.isEmpty {
            guard let possibleTagIndex = input.firstIndex(of: "<") else {
                text = html[text.startIndex...]
                break
            }

            input = html[possibleTagIndex...]
            if let tagToken = try? tagParser.parse(&input) {
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
}
