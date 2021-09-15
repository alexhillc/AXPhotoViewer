// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AXPhotoViewer",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AXPhotoViewer",
            targets: ["AXPhotoViewer"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/xiao99xiao/AXStateButton.git", .branch("master")),
        .package(url: "https://github.com/HappySwifter/FLAnimatedImage.git", from: "1.0.16")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AXPhotoViewer",
            dependencies: [
                .product(name: "AXStateButton", package: "AXStateButton"),
                .product(name: "FLAnimatedImage", package: "FLAnimatedImage"),
                .target(name: "AXExtensions"),
            ],
            path: "Source",
            exclude: [
                "Extensions/FLAnimatedImageView+AXExtensions.h",
                "Extensions/FLAnimatedImageView+AXExtensions.m",
                "Extensions/UIImageView+AXExtensions.h",
                "Extensions/UIImageView+AXExtensions.m"
            ]
        ),
        .target(name: "AXExtensions",
                dependencies: [
                    .product(name: "FLAnimatedImage", package: "FLAnimatedImage")
                ],
                path: "Source/Extensions",
                sources: [
                    "UIImageView+AXExtensions.h",
                    "UIImageView+AXExtensions.m",
                    "FLAnimatedImageView+AXExtensions.h",
                    "FLAnimatedImageView+AXExtensions.m"
                ],
                publicHeadersPath: "."
        ),
    ]
)
