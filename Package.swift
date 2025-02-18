// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "servers",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2)],
    products: [
        .library(
            name: "FileSystem",
            targets: ["FileSystem"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-system.git", branch: "main"),
        .package(url: "https://github.com/1amageek/swift-context-protocol.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FileSystem",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "ContextServer", package: "swift-context-protocol"),
            ]
        ),
        .executableTarget(
            name: "FileSystemServer",
            dependencies: [
                "FileSystem",
                .product(name: "ContextServer", package: "swift-context-protocol"),
            ]
        ),
        .testTarget(
            name: "FileSystemTests",
            dependencies: [
                "FileSystem",
            ]
        ),
    ]
)
