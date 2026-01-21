// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ProjectTracker", targets: ["ProjectTracker"])
    ],
    targets: [
        .executableTarget(
            name: "ProjectTracker",
            path: "ProjectTracker"
        )
    ]
)
