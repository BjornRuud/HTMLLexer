public enum HTMLToken: Equatable {
    case byteOrderMark
    case cdata(Substring)
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

/// A lexer (or tokenizer) to parse a HTML string into tokens representing the order of the various
/// elements. It is a non-validating HTML document parser. This means it will not check if the
/// HTML document structure is valid, but it _will_ check if the parsed HTML elements have valid
/// syntax according to the HTML specification. Elements that could not be parsed are output as text.
///
/// Example: The string "`A <b>bold</b> move`" will output
/// ```
/// [
///     .text("A "),
///     .tagStart(name: "b", attributes: [], isSelfClosing: false),
///     .text("bold"),
///     .tagEnd(name: "b"),
///     .text(" move")
/// ]
/// ```
public enum HTMLLexer {
    public static func parse(html: Substring.UTF8View) throws -> [HTMLToken] {
        var input = html
        return try Tokens().parse(&input)
    }

    public static func parse(html: Substring) throws -> [HTMLToken] {
        return try parse(html: html.utf8)
    }

    public static func parse(html: String) throws -> [HTMLToken] {
        return try parse(html: html[...].utf8)
    }
}
