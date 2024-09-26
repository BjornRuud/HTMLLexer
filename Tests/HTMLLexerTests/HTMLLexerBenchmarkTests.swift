import XCTest
@testable import HTMLLexer

class HTMLLexerBenchmarkTests: XCTestCase {
    private var htmlString: String {
        let url = Bundle.module.url(forResource: "HTMLStandard", withExtension: "html")!
        return try! String(contentsOf: url)
    }

    func testLexerSpeed() throws {
        let html = htmlString
        measure {
            _ = HTMLLexer.parse(html: html)
        }
    }
}
