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
        .library(name: "TitanFeatures", targets: ["TitanFeatures"]),
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
        .testTarget(name: "TitanFeaturesTests", dependencies: ["TitanCore", "TitanAuth", "TitanDesignSystem", "TitanLocalization", "TitanFeatures"]),

        .testTarget(
            name: "TitanKitTests",
            dependencies: [
                "TitanCore", "TitanNetworking", "TitanStorage", "TitanIcons", "TitanDesignSystem",
                "TitanNavigation", "TitanAuth", "TitanPurchase", "TitanAds",
                "TitanAnalytics", "TitanPush", "TitanRemoteConfig", "TitanLocalization",
                "TitanFeatures",
            ]
        ),
    ]
)
