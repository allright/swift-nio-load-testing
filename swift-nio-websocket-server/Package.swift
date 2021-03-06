// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-nio-websocket-server",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", .branch("nio-1.13"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-nio-websocket-server",
            dependencies: ["NIO","NIOHTTP1","NIOWebSocket"]),
        .testTarget(
            name: "swift-nio-websocket-serverTests",
            dependencies: ["swift-nio-websocket-server","NIO","NIOHTTP1","NIOWebSocket"]),
    ]
)
