// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swtws",
    products: [
        .executable(name: "swtws", targets: ["swtws"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-tweets/tweetup-kit.git", from: "0.2.0"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "swtws",
            dependencies: [
                "TweetupKit",
                "Commander",
            ]
        )
    ]
)
