// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LiquidGlassKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "LiquidGlassKit", targets: ["LiquidGlassKit"]),
    ],
    targets: [
        .target(
            name: "LiquidGlassKit",
            // .metal 源码留着给人读 / 重新编译用，但不让 SwiftPM 去编它；
            // 真正加载的是预编译好的 Resources/LiquidGlassLens.metallib。
            exclude: ["Shaders/LiquidGlassLens.metal"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "LiquidGlassDemo",
            dependencies: ["LiquidGlassKit"]
        ),
    ]
)
