// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-nio-tls-client",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", .branch("nio-1.13")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-nio-tls-client",
            dependencies: ["NIO","NIOOpenSSL"]),
        .testTarget(
            name: "swift-nio-tls-clientTests",
            dependencies: ["swift-nio-tls-client","NIO","NIOOpenSSL"]),
    ]
)
