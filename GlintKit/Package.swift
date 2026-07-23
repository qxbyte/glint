// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlintKit",
    platforms: [.macOS("26.0")],
    products: [.library(name: "GlintKit", targets: ["GlintKit"])],
    targets: [
        .target(name: "GlintKit"),
        .testTarget(name: "GlintKitTests", dependencies: ["GlintKit"]),
    ]
)
