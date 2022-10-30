// swift-tools-version: 5.7

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
            targets: ["HTMLLexer"]),
    ],
    targets: [
        .target(
            name: "HTMLLexer",
            dependencies: []),
        .testTarget(
            name: "HTMLLexerTests",
            dependencies: ["HTMLLexer"]),
    ]
)
