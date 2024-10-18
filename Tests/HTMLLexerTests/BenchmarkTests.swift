import Foundation
import Testing
@testable import HTMLLexer

@Suite(.disabled(if: true, "Used manually when optimizing"))
struct BenchmarkTests {
    let warmupCount = 1

    let iterationCount = 10

    private var htmlString: String {
        let url = Bundle.module.url(forResource: "HTMLStandard", withExtension: "html")!
        return try! String(contentsOf: url)
    }

    @Test func parsingSpeed() throws {
        try #require(iterationCount > 1)
        let html = htmlString

        for _ in 0..<warmupCount {
            _ = try HTMLLexer.parse(html: html)
        }

        var durations = [Double](repeating: 0, count: iterationCount)

        for i in 0..<iterationCount {
            let beginTime = Date().timeIntervalSinceReferenceDate
            _ = try HTMLLexer.parse(html: html)
            let endTime = Date().timeIntervalSinceReferenceDate
            durations[i] = endTime - beginTime
        }

        let average = durations.reduce(into: 0) { partialResult, duration in
            partialResult += duration
        } / Double(iterationCount)

        let sorted = durations.sorted()
        let midIndex = Float(iterationCount - 1) / 2
        let midIndexLeft = Int(floorf(midIndex))
        let midIndexRight = Int(ceilf(midIndex))
        let median = (sorted[midIndexLeft] + sorted[midIndexRight]) / 2

        print("Warmup: \(warmupCount), iterations: \(iterationCount)")
        print("Average: \(average)")
        print("Median: \(median)")
    }
}
