// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScriptToolkit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ScriptToolkit",
            targets: ["ScriptToolkit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", .branch("master")),
        .package(url: "https://github.com/kareman/SwiftShell.git", .branch("master")),
        .package(url: "https://github.com/DanielCech/Moderator.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ScriptToolkit",
            dependencies: ["Files", "SwiftShell", "Moderator"]
        ),
        .testTarget(
            name: "ScriptToolkitTests",
            dependencies: ["ScriptToolkit"]
        )
    ]
)
