// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "purple-bencode",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8), .macCatalyst(.v15), .driverKit(.v21)],
    products: [
        .library(name: "PurpleBencode", targets: ["PurpleBencode"]),
    ],
    targets: [
        .target(name: "PurpleBencode"),
        .testTarget(name: "PurpleBencodeTests", dependencies: ["PurpleBencode"]),
    ]
)
