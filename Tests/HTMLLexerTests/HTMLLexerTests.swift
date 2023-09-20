import XCTest
@testable import HTMLLexer

final class HTMLLexerTests: XCTestCase {
    func testByteOrderMark() throws {
        let html = "\u{FEFF} asdf"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .byteOrderMark,
            .text(" asdf")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testNoTag() throws {
        let html = "<< > < <"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .text(html)
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testCommentTag() throws {
        let html = "<!-- Foo -->"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .comment(" Foo ")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testCommentNoEnd() throws {
        let html = "Asdf <!-- Foo"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .text("Asdf <!-- Foo")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testCommentDoubleEnd() throws {
        let html = "<!-- Foo -->-->"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .comment(" Foo "),
            .text("-->")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginTag() throws {
        let html = "<b><b >"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "b", attributes: [:], isSelfClosing: false),
            .tagStart(name: "b", attributes: [:], isSelfClosing: false),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginMalformedTag() throws {
        let html = "< b><b🎃 >"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .text("< b><b🎃 >")
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginSelfClosedTag() throws {
        let html = "<div/><div />"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: [:], isSelfClosing: true),
            .tagStart(name: "div", attributes: [:], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testBeginSelfClosedMalformedTag() throws {
        let html = "<div/ ><div / >"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .text(html)
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testEndTag() throws {
        let html = "</b></b >"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagEnd(name: "b"),
            .tagEnd(name: "b"),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testEndMalformedTag() throws {
        let html = "</ b> </b/> </b /> </🎃>"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .text(html)
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeSingle() throws {
        let html = "<div custom><div  custom/><div custom ><div custom />"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: true),
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeSingleEqual() throws {
        let html = "<div custom=><div  custom=/><div custom= ><div custom= />"
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: true),
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["custom": ""], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeAmpersandQuotedValue() throws {
        let html = #"<div foo="bar"><div  foo="bar"/><div foo="bar" ><div foo="bar" />"#
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: true),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeApostropheQuotedValue() throws {
        let html = #"<div foo='bar'><div  foo='bar'/><div foo='bar' ><div foo='bar' />"#
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: true),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: true),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeUnquotedValue() throws {
        let html = #"<div foo=bar><div  foo=bar /><div foo=bar bar=foo >"#
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: false),
            .tagStart(name: "div", attributes: ["foo": "bar"], isSelfClosing: true),
            .tagStart(name: "div", attributes: ["foo": "bar", "bar": "foo"], isSelfClosing: false),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testTagAttributeMix() throws {
        let html = #"<div a b=foo c d="foo" e f='foo'>"#
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .tagStart(name: "div", attributes: [
                "a": "",
                "b": "foo",
                "c": "",
                "d": "foo",
                "e": "",
                "f": "foo"
            ], isSelfClosing: false),
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testDoctype() throws {
        let html = #"<!DOCTYPE html><!doctype HTML><!dOcTyPe HtMl>"#
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .doctype(type: "html", legacy: nil),
            .doctype(type: "HTML", legacy: nil),
            .doctype(type: "HtMl", legacy: nil)
        ]
        XCTAssertEqual(tokens, reference)
    }

    func testDoctypeLegacy() throws {
        let html = #"<!DOCTYPE html SYSTEM "about:legacy-compat">"#
        let tokens = HTMLLexer.parse(html: html)
        let reference: [HTMLLexer.Token] = [
            .doctype(type: "html", legacy: #"SYSTEM "about:legacy-compat""#)
        ]
        XCTAssertEqual(tokens, reference)
    }
}
