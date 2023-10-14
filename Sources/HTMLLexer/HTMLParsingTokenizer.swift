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
        Skip { CharacterSet.asciiWhitespace }
        Prefix(4).filter { $0.lowercased() == "html" }
        Skip { CharacterSet.asciiWhitespace }
        Prefix { $0 != ">" }.map { $0.isEmpty ? nil : $0 }
        ">"
    }.map(HTMLToken.doctype(name:type:legacy:))


/*
 Start tags must have the following format:

 The first character of a start tag must be a U+003C LESS-THAN SIGN character (<).

 The next few characters of a start tag must be the element's tag name.

 If there are to be any attributes in the next step, there must first be one or more ASCII whitespace.

 Then, the start tag may have a number of attributes, the syntax for which is described below. Attributes must be separated from each other by one or more ASCII whitespace.

 After the attributes, or after the tag name if there are no attributes, there may be one or more ASCII whitespace. (Some attributes are required to be followed by a space. See the attributes section below.)

 Then, if the element is one of the void elements, or if the element is a foreign element, then there may be a single U+002F SOLIDUS character (/), which on foreign elements marks the start tag as self-closing. On void elements, it does not mark the start tag as self-closing but instead is unnecessary and has no effect of any kind. For such void elements, it should be used only with caution — especially since, if directly preceded by an unquoted attribute value, it becomes part of the attribute value rather than being discarded by the parser.

 Finally, start tags must be closed by a U+003E GREATER-THAN SIGN character (>).
 */
    // https://html.spec.whatwg.org/multipage/syntax.html#start-tags
    static let startTag = Backtracking {
        "<"
        CharacterSet.asciiAlphanumerics
        Skip { CharacterSet.asciiWhitespace }
        Always([HTMLToken.TagAttribute]())
        Optionally { "/" }.map { $0 != nil }
        ">"
    }.map(HTMLToken.tagStart(name:attributes:isSelfClosing:))

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
        // TODO: Support unquoted value
        //CharacterSet.htmlNonQuotedAttributeValue
        //    .filter { $0.last != "/" }
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
    }.map(HTMLToken.TagAttribute.init(name:value:))

    static let tagAttributes = Many {
        tagAttribute
    } separator: {
        CharacterSet.asciiWhitespace
    } terminator: {
        OneOf {
            Peek { ">" }
            Peek { "/" }
            End()
        }
    }
}

public struct HTMLParsingTokenizer: Sequence, IteratorProtocol {
    public typealias Element = HTMLLexer.Token

    public init(html: String) {
    }

    public mutating func next() -> HTMLLexer.Token? {
//        if let queuedToken {
//            self.queuedToken = nil
//            return queuedToken
//        }
//        if shouldParseBom {
//            shouldParseBom = false
//            if let token = bomParser() {
//                return token
//            }
//        }
//        return tagAndTextParser()
        return nil
    }

//    private mutating func tagAndTextParser() -> HTMLLexer.Token? {
//        while !scanner.isAtEnd {
//            if let foundText = scanUpToString("<") {
//                accumulatedText.append(String(foundText))
//            }
//            if scanner.isAtEnd { break }
//            let potentialTagIndex = currentIndex
//            if let token = scanTag() {
//                if accumulatedText.isEmpty {
//                    return token
//                }
//                queuedToken = token
//                return accumulatedTextToken()
//            } else {
//                // Not a tag, append text scanned while searching
//                let foundText = scanner.collection[potentialTagIndex..<currentIndex]
//                accumulatedText.append(String(foundText))
//            }
//        }
//        return accumulatedTextToken()
//    }
}
