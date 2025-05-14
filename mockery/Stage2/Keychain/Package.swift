// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Keychain",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
    ],
    products: [
        .library(
            name: "Keychain",
            targets: ["Keychain"]),
    ],
    targets: [
        .target(
            name: "Keychain"),
        .testTarget(
            name: "KeychainTests",
            dependencies: ["Keychain"]
        ),
    ]
)
