import Testing
@testable import HTMLLexer

@Suite struct ParsingTests {
    @Test func byteOrderMark() throws {
        let html = "\u{FEFF} asdf"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .byteOrderMark,
            .text(" asdf")
        ]
        #expect(tokens == reference)
    }

    @Test func noTag() throws {
        let html = "<< > < <"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .text("<< > < <")
        ]
        #expect(tokens == reference)
    }

    @Test func commentTag() throws {
        let html = "<!-- Foo -->"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .comment(" Foo ")
        ]
        #expect(tokens == reference)
    }

    @Test func commentNoEnd() throws {
        let html = "Asdf <!-- Foo"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .text("Asdf <!-- Foo")
        ]
        #expect(tokens == reference)
    }

    @Test func commentDoubleEnd() throws {
        let html = "<!-- Foo -->-->"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .comment(" Foo "),
            .text("-->")
        ]
        #expect(tokens == reference)
    }

    @Test func startTag() throws {
        let html = "<b><b >"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "b", attributes: [], isSelfClosing: false),
            .tagStart(name: "b", attributes: [], isSelfClosing: false),
        ]
        #expect(tokens == reference)
    }

    @Test func startTagNoEnd() throws {
        let html = "<b><b "
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "b", attributes: [], isSelfClosing: false),
            .text("<b ")
        ]
        #expect(tokens == reference)
    }

    @Test func startTagMalformed() throws {
        let html = "< b><b🎃 >"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .text("< b><b🎃 >")
        ]
        #expect(tokens == reference)
    }

    @Test func startTagSelfClosed() throws {
        let html = "<div/><div />"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [], isSelfClosing: true),
            .tagStart(name: "div", attributes: [], isSelfClosing: true),
        ]
        #expect(tokens == reference)
    }

    @Test func startTagSelfClosedMalformed() throws {
        let html = "<div/ ><div / >"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .text("<div/ ><div / >")
        ]
        #expect(tokens == reference)
    }

    @Test func endTag() throws {
        let html = "</b></b >"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagEnd(name: "b"),
            .tagEnd(name: "b"),
        ]
        #expect(tokens == reference)
    }

    @Test func endTagMalformed() throws {
        let html = "</ b> </b/> </b /> </🎃>"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .text("</ b> </b/> </b /> </🎃>")
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeSingle() throws {
        let html = "<div custom><div  custom/><div custom ><div custom />"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: true),
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: true),
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeSingleEqual() throws {
        let html = "<div custom=><div  custom=/><div custom= ><div custom= />"
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .text("<div custom=><div  custom=/><div custom= ><div custom= />")
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeDoubleQuotedValue() throws {
        let html = #"<div foo="bar"><div  foo="bar"/><div foo="bar" ><div foo="bar" />"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeSingleQuotedValue() throws {
        let html = #"<div foo='bar'><div  foo='bar'/><div foo='bar' ><div foo='bar' />"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeUnquotedValue() throws {
        let html = #"<div foo=bar><div  foo=bar /><div foo=bar bar=foo >"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
            .tagStart(name: "div", attributes: [
                .init(name: "foo", value: "bar"),
                .init(name: "bar", value: "foo")
            ], isSelfClosing: false),
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeUnquotedValueSelfClosing() throws {
        let html = #"<div foo=bar/>"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true)
        ]
        #expect(tokens == reference)
    }

    @Test func tagAttributeMix() throws {
        let html = #"<div a b=foo c d="foo" e f='foo'>"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .tagStart(name: "div", attributes: [
                .init(name: "a", value: nil),
                .init(name: "b", value: "foo"),
                .init(name: "c", value: nil),
                .init(name: "d", value: "foo"),
                .init(name: "e", value: nil),
                .init(name: "f", value: "foo")
            ], isSelfClosing: false),
        ]
        #expect(tokens == reference)
    }

    @Test func doctype() throws {
        let html = #"<!DOCTYPE html><!doctype HTML><!dOcTyPe HtMl>"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .doctype(name: "DOCTYPE", type: "html", legacy: nil),
            .doctype(name: "doctype", type: "HTML", legacy: nil),
            .doctype(name: "dOcTyPe", type: "HtMl", legacy: nil)
        ]
        #expect(tokens == reference)
    }

    @Test func doctypeLegacy() throws {
        let html = #"<!DOCTYPE html SYSTEM "about:legacy-compat">"#
        let tokens = try HTMLLexer.parse(html: html)
        let reference: [HTMLToken] = [
            .doctype(name: "DOCTYPE", type: "html", legacy: "SYSTEM \"about:legacy-compat\"")
        ]
        #expect(tokens == reference)
    }
}
