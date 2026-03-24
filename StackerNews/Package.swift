// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StackerNews",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "StackerNews",
            targets: ["StackerNews"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "StackerNews",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "StackerNewsTests",
            dependencies: ["StackerNews"]
        ),
    ]
)
