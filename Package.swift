// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Slox",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-testing.git", .upToNextMajor(from: "0.10.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Lox",
            dependencies: []
        ),
        .executableTarget(
            name: "Slox",
            dependencies: [
                "Lox",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "AbstractSyntaxTreeGenerator",
            dependencies: [
                "Lox",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "LoxTests", dependencies: [
            "Lox",
            .product(name: "Testing", package: "swift-testing")
        ])
    ]
)

