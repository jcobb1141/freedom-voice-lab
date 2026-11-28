// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "PrivateVoiceSpike",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .executable(name: "VoiceRuntime", targets: ["VoiceRuntime"])
    ],
    dependencies: [
        .package(url: "https://github.com/Neywa-Labs/mlx-audio-swift.git",
                 revision: "c7755e2504181a771941bb6f9f26ea79b3cdfce3"),
        .package(url: "https://github.com/ml-explore/mlx-swift.git", exact: "0.33.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", exact: "1.4.0"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", exact: "1.0.1")
    ],
    targets: [
        .executableTarget(name: "VoiceRuntime", dependencies: [
            .product(name: "MLXAudioTTS", package: "mlx-audio-swift"),
            .product(name: "MLXAudioCore", package: "mlx-audio-swift"),
            .product(name: "MLX", package: "mlx-swift")
        ])
    ]
)
