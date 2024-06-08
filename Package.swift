// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "PerformanceMonitor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "PerformanceMonitor", targets: ["PerformanceMonitor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IgorMuzyka/DisplayLink", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "PerformanceMonitor",
            dependencies: [
                .byName(name: "DisplayLink"),
            ],
            path: "./Sources/"
        ),
    ]
)
