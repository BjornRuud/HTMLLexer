import HTMLLexer
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .task {
            guard
                let htmlUrl = Bundle.main.url(forResource: "HTMLStandard", withExtension: "html"),
                let html = try? String(contentsOf: htmlUrl)
            else {
                return
            }
            let tokens = HTMLLexerParsing.parse(html: html)
        }
    }
}

#Preview {
    ContentView()
}
