/// A lexer/tokenizer to parse a HTML string into tokens representing the order of the various
/// elements. It is a non-validating HTML document parser. This means it will not check if the
/// HTML document structure is valid, but it _will_ check if the parsed HTML elements are valid
/// according to the HTML specification. Elements that could not be parsed are output as text.
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
    public typealias TokenHandler = (HTMLToken) -> Void

    public static func parse(html: String, tokenHandler: TokenHandler) {
        for token in HTMLTokenizer(html: html) {
            tokenHandler(token)
        }
    }

    public static func parse(html: String) -> [HTMLToken] {
        return HTMLTokenizer(html: html).reduce(into: [HTMLToken]()) { tokens, token in
            tokens.append(token)
        }
    }
}
