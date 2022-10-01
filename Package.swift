// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let name = "NTPSession"
private let exe = "swiftntp"

let package = Package(
    name: "\(name)",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "\(name)",
            targets: ["\(name)"]),
        .executable(
            name: "\(exe)",
            targets: ["\(exe)"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "\(exe)", 
            dependencies: [Target.Dependency(stringLiteral: "\(name)")]),
        .target(
            name: "\(name)",
            dependencies: []),
        .testTarget(
            name: "\(name)Tests",
            dependencies: [Target.Dependency(stringLiteral: "\(name)")])
    ]
)
