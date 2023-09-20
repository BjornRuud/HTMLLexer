/// A lexer/tokenizer to parse a HTML string into tokens representing the order of the various
/// elements. It is a non-validating parser. This means it will not check if the HTML structure
/// is valid, but it _will_ check if the parsed HTML elements are valid according to the HTML
/// specification. Elements that could not be parsed are output as text.
///
/// Example: The string "`A <b>bold</b> move`" will output
/// ```
/// [
///     .text("A "),
///     .tagStart(name: "b", attributes: [:], isSelfClosing: false),
///     .text("bold"),
///     .tagEnd(name: "b"),
///     .text(" move")
/// ]
/// ```
public struct HTMLLexer {
    public enum Token: Equatable {
        case byteOrderMark
        case comment(String)
        case doctype(type: String, legacy: String?)
        case tagStart(name: String, attributes: [String: String], isSelfClosing: Bool)
        case tagEnd(name: String)
        case text(String)
    }

    public typealias TokenHandler = (Token) -> Void

    public static func parse(html: String, tokenHandler: TokenHandler) {
        for token in HTMLTokenizer(html: html) {
            tokenHandler(token)
        }
    }

    public static func parse(html: String) -> [Token] {
        return HTMLTokenizer(html: html).reduce(into: [Token]()) { tokens, token in
            tokens.append(token)
        }
    }
}
