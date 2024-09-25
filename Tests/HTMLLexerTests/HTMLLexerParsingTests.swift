import XCTest
@testable import HTMLLexer

final class HTMLLexerParsingTests: XCTestCase {
    func testByteOrderMark() throws {
        let html = "\u{FEFF} asdf"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .byteOrderMark,
            .text(" asdf")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testNoTag() throws {
        let html = "<< > < <"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .text("<< > < <")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testCommentTag() throws {
        let html = "<!-- Foo -->"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .comment(" Foo ")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testCommentNoEnd() throws {
        let html = "Asdf <!-- Foo"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .text("Asdf <!-- Foo")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testCommentDoubleEnd() throws {
        let html = "<!-- Foo -->-->"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .comment(" Foo "),
            .text("-->")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginTag() throws {
        let html = "<b><b >"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "b", attributes: [], isSelfClosing: false),
            .tagStart(name: "b", attributes: [], isSelfClosing: false),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testStartTagNoEnd() throws {
        let html = "<b><b "
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "b", attributes: [], isSelfClosing: false),
            .text("<b ")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginMalformedTag() throws {
        let html = "< b><b🎃 >"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .text("< b><b🎃 >")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginSelfClosedTag() throws {
        let html = "<div/><div />"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "div", attributes: [], isSelfClosing: true),
            .tagStart(name: "div", attributes: [], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginSelfClosedMalformedTag() throws {
        let html = "<div/ ><div / >"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .text("<div/ ><div / >")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testEndTag() throws {
        let html = "</b></b >"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagEnd(name: "b"),
            .tagEnd(name: "b"),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testEndMalformedTag() throws {
        let html = "</ b> </b/> </b /> </🎃>"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .text("</ b> </b/> </b /> </🎃>")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeSingle() throws {
        let html = "<div custom><div  custom/><div custom ><div custom />"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: true),
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "custom", value: nil)], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeSingleEqual() throws {
        let html = "<div custom=><div  custom=/><div custom= ><div custom= />"
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .text("<div custom=><div  custom=/><div custom= ><div custom= />")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeAmpersandQuotedValue() throws {
        let html = #"<div foo="bar"><div  foo="bar"/><div foo="bar" ><div foo="bar" />"#
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeApostropheQuotedValue() throws {
        let html = #"<div foo='bar'><div  foo='bar'/><div foo='bar' ><div foo='bar' />"#
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeUnquotedValue() throws {
        let html = #"<div foo=bar><div  foo=bar /><div foo=bar bar=foo >"#
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: false),
            .tagStart(name: "div", attributes: [.init(name: "foo", value: "bar")], isSelfClosing: true),
            .tagStart(name: "div", attributes: [
                .init(name: "foo", value: "bar"),
                .init(name: "bar", value: "foo")
            ], isSelfClosing: false),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeMix() throws {
        let html = #"<div a b=foo c d="foo" e f='foo'>"#
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .tagStart(name: "div", attributes: [
                .init(name: "a", value: nil),
                .init(name: "b", value: "foo"),
                .init(name: "c", value: nil),
                .init(name: "d", value: "foo"),
                .init(name: "e", value: nil),
                .init(name: "f", value: "foo")
            ], isSelfClosing: false),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testDoctype() throws {
        let html = #"<!DOCTYPE html><!doctype HTML><!dOcTyPe HtMl>"#
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .doctype(name: "DOCTYPE", type: "html", legacy: nil),
            .doctype(name: "doctype", type: "HTML", legacy: nil),
            .doctype(name: "dOcTyPe", type: "HtMl", legacy: nil)
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testDoctypeLegacy() throws {
        let html = #"<!DOCTYPE html SYSTEM "about:legacy-compat">"#
        let tokens = try HTMLLexerParsing.parse(html: html)
        let reference: [HTMLParsingToken] = [
            .doctype(name: "DOCTYPE", type: "html", legacy: "SYSTEM \"about:legacy-compat\"")
        ]
        XCTAssertEqual(tokens, reference)
    }
}
