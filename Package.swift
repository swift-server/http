// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftServerHTTP",
    products: [
    	.library(name: "HTTP", targets: ["HTTP"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "CHTTPParser"),
        .target(name: "HTTP", dependencies: ["CHTTPParser"]),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"])
    ]
)
