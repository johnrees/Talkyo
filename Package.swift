// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Talkyo",
    platforms: [
        .iOS(.v18)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "Talkyo",
            dependencies: ["WhisperKit"]
        )
    ]
)