// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SwiftServerHttp",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/CHTTPParser.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: 0, minor: 12),
    ]
)

#if os(Linux)
    package.dependencies.append(
        .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", majorVersion: 0, minor: 9))
#endif
