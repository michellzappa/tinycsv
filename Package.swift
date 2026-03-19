// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyCSV",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../Packages/TinyKit"),
    ],
    targets: [
        .executableTarget(
            name: "TinyCSV",
            dependencies: ["TinyKit"],
            path: "Sources/TinyCSV",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
