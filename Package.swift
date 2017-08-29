// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SwiftServerHTTP",
    targets: [
        Target(name: "CHTTPParser"),
        Target(name: "HTTP", dependencies: [.Target(name: "CHTTPParser")]),
    ]
)

