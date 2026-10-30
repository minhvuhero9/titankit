// swift-tools-version: 6.0
import PackageDescription

// Each module is its own library so an app only links what it uses.
// Dependencies only point downward: Foundation -> UI/Services -> Features.
let foundation: [Target.Dependency] = ["TitanCore"]

let package = Package(
    name: "TitanKit",
    defaultLocalization: "vi",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TitanCore", targets: ["TitanCore"]),
        .library(name: "TitanNetworking", targets: ["TitanNetworking"]),
        .library(name: "TitanStorage", targets: ["TitanStorage"]),
        .library(name: "TitanIcons", targets: ["TitanIcons"]),
        .library(name: "TitanDesignSystem", targets: ["TitanDesignSystem"]),
        .library(name: "TitanNavigation", targets: ["TitanNavigation"]),
        .library(name: "TitanAuth", targets: ["TitanAuth"]),
        .library(name: "TitanPurchase", targets: ["TitanPurchase"]),
        .library(name: "TitanAds", targets: ["TitanAds"]),
        .library(name: "TitanAnalytics", targets: ["TitanAnalytics"]),
        .library(name: "TitanPush", targets: ["TitanPush"]),
        .library(name: "TitanRemoteConfig", targets: ["TitanRemoteConfig"]),
        .library(name: "TitanLocalization", targets: ["TitanLocalization"]),
        .library(name: "TitanSpeech", targets: ["TitanSpeech"]),
        .library(name: "TitanAI", targets: ["TitanAI"]),
        .library(name: "TitanFeatures", targets: ["TitanFeatures"]),
    ],
    dependencies: [
        // Only the snapshot tests use it; apps never link it.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.17.6"),
    ],
    targets: [
        // Foundation
        .target(name: "TitanCore"),
        .target(name: "TitanNetworking", dependencies: foundation),
        .target(name: "TitanStorage", dependencies: foundation),

        // UI
        .target(name: "TitanIcons", resources: [.process("Resources")]),
        .target(
            name: "TitanDesignSystem",
            dependencies: foundation + ["TitanLocalization", "TitanIcons"],
            resources: [.process("Resources")]
        ),
        .target(name: "TitanNavigation", dependencies: foundation),

        // Services
        .target(name: "TitanAuth", dependencies: foundation + ["TitanStorage"]),
        .target(name: "TitanPurchase", dependencies: foundation),
        .target(name: "TitanAds", dependencies: foundation),
        .target(name: "TitanAnalytics", dependencies: foundation),
        .target(name: "TitanPush", dependencies: foundation + ["TitanNavigation"]),
        .target(name: "TitanRemoteConfig", dependencies: foundation),
        .target(name: "TitanLocalization", dependencies: foundation, resources: [.process("Resources")]),
        .target(name: "TitanSpeech", dependencies: foundation),
        .target(name: "TitanAI", dependencies: foundation),

        // Ready-made screens
        .target(
            name: "TitanFeatures",
            dependencies: foundation + [
                "TitanDesignSystem", "TitanIcons", "TitanNavigation", "TitanAuth",
                "TitanPurchase", "TitanRemoteConfig", "TitanLocalization",
            ]
        ),

        .testTarget(name: "TitanCoreTests", dependencies: ["TitanCore"]),
        .testTarget(name: "TitanNetworkingTests", dependencies: ["TitanCore", "TitanNetworking"]),
        .testTarget(name: "TitanStorageTests", dependencies: ["TitanCore", "TitanStorage"]),
        .testTarget(name: "TitanIconsTests", dependencies: ["TitanIcons"]),
        .testTarget(name: "TitanDesignSystemTests", dependencies: ["TitanDesignSystem"]),
        .testTarget(name: "TitanNavigationTests", dependencies: ["TitanNavigation"]),
        .testTarget(name: "TitanLocalizationTests", dependencies: ["TitanCore", "TitanLocalization"]),
        .testTarget(name: "TitanAuthTests", dependencies: ["TitanCore", "TitanAuth"]),
        .testTarget(name: "TitanRemoteConfigTests", dependencies: ["TitanCore", "TitanRemoteConfig"]),
        .testTarget(name: "TitanPurchaseTests", dependencies: ["TitanCore", "TitanPurchase"]),
        .testTarget(name: "TitanSpeechTests", dependencies: ["TitanCore", "TitanSpeech"]),
        .testTarget(name: "TitanAITests", dependencies: ["TitanCore", "TitanAI"]),
        .testTarget(name: "TitanAnalyticsTests", dependencies: ["TitanCore", "TitanAnalytics"]),
        .testTarget(name: "TitanFeaturesTests", dependencies: ["TitanCore", "TitanAuth", "TitanDesignSystem", "TitanLocalization", "TitanPurchase", "TitanFeatures"]),

        // Reference images live in __Snapshots__; record them with the Snapshots workflow.
        .testTarget(
            name: "TitanSnapshotTests",
            dependencies: [
                "TitanDesignSystem", "TitanIcons",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),

        .testTarget(
            name: "TitanKitTests",
            dependencies: [
                "TitanCore", "TitanNetworking", "TitanStorage", "TitanIcons", "TitanDesignSystem",
                "TitanNavigation", "TitanAuth", "TitanPurchase", "TitanAds",
                "TitanAnalytics", "TitanPush", "TitanRemoteConfig", "TitanLocalization",
                "TitanSpeech", "TitanAI", "TitanFeatures",
            ]
        ),
    ]
)
