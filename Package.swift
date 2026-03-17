// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TinyCSV",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "Packages/TinyKit"),
    ],
    targets: [
        .executableTarget(
            name: "TinyCSV",
            dependencies: ["TinyKit"],
            path: "Sources/TinyCSV"
        ),
    ]
)
