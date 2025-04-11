// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cowsay",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/kareman/SwiftShell", from: "5.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "Cowsay",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftShell", package: "SwiftShell"),
            ]
        ),
        .testTarget(
            name: "CowsayTests",
            dependencies: [
                "Cowsay",
            ]
        ),
    ]
)
