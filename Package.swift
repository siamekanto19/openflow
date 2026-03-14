// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OpenFlow", targets: ["OpenFlow"])
    ],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.2.0"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
    ],
    targets: [
        .executableTarget(
            name: "OpenFlow",
            dependencies: [
                "SwiftWhisper",
                "HotKey",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "OpenFlow",
            exclude: [
                "Resources/Info.plist",
                "Resources/Whisper.entitlements",
                "Resources/AppIcon.icns",
            ],
            resources: [
                .copy("Resources/Assets.xcassets"),
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
            ]
        )
    ]
)
