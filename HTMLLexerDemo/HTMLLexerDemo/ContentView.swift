import HTMLLexer
import SwiftUI

struct ContentView: View {
    @State private var handcraftedTime: TimeInterval = 0
    @State private var swiftParsingTime: TimeInterval = 0
    @State private var isBenchmarking: Bool = false

    var body: some View {
        VStack {
            Button("Benchmark", action: onBenchmarkTapped)
            Text("Handcrafted: \(handcraftedTime)")
            Text("Swift-Parsing: \(swiftParsingTime)")
            if isBenchmarking {
                ProgressView()
            }
        }
        .padding()
    }

    func onBenchmarkTapped() {
        guard !isBenchmarking else { return }
        isBenchmarking = true
        Task {
            await startBenchmark()
        }
    }

    private func loadHtml() async -> String? {
        guard
            let htmlUrl = Bundle.main.url(forResource: "HTMLStandard", withExtension: "html")
        else { return nil }
        return try? String(contentsOf: htmlUrl)
    }

    @MainActor
    private func startBenchmark() async {
        defer { isBenchmarking = false }
        guard let html = await loadHtml() else { return }
        let handcraftedTime = await benchmarkHandcrafted(html: html)
        self.handcraftedTime = handcraftedTime
        let swiftParsingTime = await benchmarkSwiftParsing(html: html)
        self.swiftParsingTime = swiftParsingTime
    }

    private func benchmarkHandcrafted(html: String) async -> TimeInterval {
        let startTime = Date()
        let _ = HTMLLexer.parse(html: html)
        let stopTime = Date()
        return stopTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
    }

    private func benchmarkSwiftParsing(html: String) async -> TimeInterval {
        let startTime = Date()
        let _ = HTMLLexerParsing.parse(html: html)
        let stopTime = Date()
        return stopTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
    }
}

#Preview {
    ContentView()
}
