// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimeoutFetcher",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TimeoutFetcher",
            targets: ["TimeoutFetcher"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TimeoutFetcher",
            dependencies: [
                .product(name: "RxSwift", package: "rxswift")
            ]),
        .testTarget(
            name: "TimeoutFetcherTests",
            dependencies: [
                "TimeoutFetcher",
                .product(name: "RxBlocking", package: "rxswift") 
            ]),
    ]
)
