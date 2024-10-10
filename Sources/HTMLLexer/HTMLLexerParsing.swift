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

public enum HTMLLexerParsing {
    public static func parse(html: Substring) throws -> [HTMLParsingToken] {
        var input = html
        return try Document().parse(&input)
    }

    public static func parse(html: String) throws -> [HTMLParsingToken] {
        return try parse(html: html[...])
    }
}
