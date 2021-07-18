// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZaturnSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ZaturnSDK",
            targets: ["ZaturnSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "ShamirSecretShare", url: "https://github.com/kryptco/SecretShare.swift", "1.0.0"..<"2.0.0"),
        .package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium.git", "0.9.1"..<"1.0.0"),
        .package(name: "GoogleSignIn", url: "https://github.com/airgap-it/GoogleSignIn-iOS", .branch("main"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ZaturnSDK",
            dependencies: ["ShamirSecretShare", "Sodium", .product(name: "Clibsodium", package: "Sodium"), "GoogleSignIn"]),
        .testTarget(
            name: "ZaturnSDKTests",
            dependencies: ["ZaturnSDK"]),
    ]
)
