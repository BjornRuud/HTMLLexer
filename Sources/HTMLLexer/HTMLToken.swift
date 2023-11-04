public enum HTMLToken: Equatable {
    case byteOrderMark
    case comment(String)
    case doctype(name: String, type: String, legacy: String?)
    case tagStart(name: String, attributes: [TagAttribute], isSelfClosing: Bool)
    case tagEnd(name: String)
    case text(String)
}

extension HTMLToken {
    public struct TagAttribute: Equatable {
        public let name: String
        public let value: String?

        public init(name: String, value: String?) {
            self.name = name
            self.value = value
        }
    }
}
