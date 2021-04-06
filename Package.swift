// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwizzleHelper",
    platforms: [.macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
    products:
    [
        .library(
            name: "SwizzleHelper",
            targets: ["SwizzleHelper", "SwizzleHelperObjC"]
        ),
    ],
    dependencies: [],
    targets:
    [
        .target(
            name: "SwizzleHelper",
            dependencies: ["SwizzleHelperObjC"]
        ),
        .target(
            name: "SwizzleHelperObjC",
            dependencies: [],
            path: "SwizzleHelperObjC",
            cSettings:
            [
                .headerSearchPath("Internal"),
                .unsafeFlags(["-O0"]),
            ]
        ),
        .testTarget(
            name: "SwizzleHelperTests",
            dependencies: ["SwizzleHelper"]
        ),
    ]
)
