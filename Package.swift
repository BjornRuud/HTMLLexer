// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HTMLLexer",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "HTMLLexer",
            targets: ["HTMLLexer"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-parsing.git",
            from: "0.13.0"
        )
    ],
    targets: [
        .target(
            name: "HTMLLexer",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing")
            ]

        ),
        .testTarget(
            name: "HTMLLexerTests",
            dependencies: ["HTMLLexer"],
            resources: [.process("Data")]
        ),
    ]
)
