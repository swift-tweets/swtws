// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swtws",
    products: [
        .executable(name: "swtws", targets: ["swtws"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-tweets/tweetup-kit.git", from: "0.0.0")
    ],
    targets: [
        .target(
            name: "swtws",
            dependencies: [
                "TweetupKit",
            ]
        )
    ]
)
