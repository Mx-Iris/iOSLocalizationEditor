// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizationEditorModules",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Utils",
            targets: ["Utils"]
        ),
        .library(
            name: "Models",
            targets: ["Models"]
        ),
        .library(
            name: "Providers",
            targets: ["Providers"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMajor(from: "1.0.3") // or `.upToNextMinor
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Utils",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "Modules/Utils"
        ),
        .target(
            name: "Models",
            dependencies: ["Utils"],
            path: "Modules/Models"
        ),
        .target(
            name: "Providers",
            dependencies: [
                "Models", "Utils",
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "Modules/Providers"
        ),
    ]
)
