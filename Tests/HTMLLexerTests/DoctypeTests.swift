import Testing
@testable import HTMLLexer

@Suite struct DoctypeTests {
    @Test func docType() throws {
        let parser = DocType()
        let text = "DOCTYPE html>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "DOCTYPE", type: "html", legacy: nil)
        #expect(token == reference)
    }

    @Test func docTypeInvalid() throws {
        let parser = DocType()
        let text = "DOC html>".utf8
        var input = text[...]
        #expect(throws: (any Error).self) { try parser.parse(&input) }
    }

    @Test func docTypeInverse() throws {
        let parser = DocType()
        let text = "doctype HTML>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "doctype", type: "HTML", legacy: nil)
        #expect(token == reference)
    }

    @Test func docTypeMixed() throws {
        let parser = DocType()
        let text = "dOcTyPe HtMl>".utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "dOcTyPe", type: "HtMl", legacy: nil)
        #expect(token == reference)
    }

    @Test func docTypeLegacy() throws {
        let parser = DocType()
        let text = #"DOCTYPE html SYSTEM "about:legacy-compat">"#.utf8
        var input = text[...]
        let token = try parser.parse(&input)
        let reference = HTMLToken.doctype(name: "DOCTYPE", type: "html", legacy: #"SYSTEM "about:legacy-compat""#)
        #expect(token == reference)
    }
}
