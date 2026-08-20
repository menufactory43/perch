// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Perch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PerchCore", targets: ["PerchCore"]),
        .executable(name: "perch", targets: ["perch"]),
    ],
    targets: [
        .target(
            name: "PerchCore",
            resources: [
                .copy("Resources/catalog.json"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "perch",
            dependencies: ["PerchCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "PerchCoreTests",
            dependencies: ["PerchCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
