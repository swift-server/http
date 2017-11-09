// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftServerHttp",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "HTTP",
            targets: ["HTTP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // ServerSecurity: common headers, definitions and protocols
        .package(url: "https://github.com/gtaban/security.git", from: "0.0.0"),
        // TLSService: implementation of ServerSecurity using OpenSSL and SecureTransport
        .package(url: "https://github.com/gtaban/TLSService.git", from: "0.20.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CHTTPParser",
            dependencies: []),
        .target(
            name: "HTTP",
            dependencies: ["CHTTPParser", "ServerSecurity", "TLSService"]),
        .testTarget(
            name: "HTTPTests",
            dependencies: ["HTTP"]),
    ]
)
