import PackageDescription

let package = Package(
    name: "swtws",
    dependencies: [
        .Package(url: "https://github.com/swift-tweets/tweetup-kit.git", "0.1.0-beta")
    ]
)
