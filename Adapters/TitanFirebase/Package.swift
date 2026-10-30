// swift-tools-version: 6.0
import PackageDescription

// Firebase behind the TitanKit protocols. Kept out of Packages/TitanKit so the kit builds and
// tests without the Firebase SDK; an app adds only the targets it needs.
let titanKit = "TitanKit"
let firebase = "firebase-ios-sdk"

let package = Package(
    name: "TitanFirebase",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TitanFirebaseCore", targets: ["TitanFirebaseCore"]),
        .library(name: "TitanFirebaseAuth", targets: ["TitanFirebaseAuth"]),
        .library(name: "TitanFirebaseAnalytics", targets: ["TitanFirebaseAnalytics"]),
        .library(name: "TitanFirebaseRemoteConfig", targets: ["TitanFirebaseRemoteConfig"]),
    ],
    dependencies: [
        .package(path: "../../Packages/TitanKit"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.19.3"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", exact: "9.2.0"),
    ],
    targets: [
        .target(
            name: "TitanFirebaseCore",
            dependencies: [
                .product(name: "TitanCore", package: titanKit),
                .product(name: "FirebaseCore", package: firebase),
            ]
        ),
        .target(
            name: "TitanFirebaseAuth",
            dependencies: [
                "TitanFirebaseCore",
                .product(name: "TitanAuth", package: titanKit),
                .product(name: "FirebaseAuth", package: firebase),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ]
        ),
        .target(
            name: "TitanFirebaseAnalytics",
            dependencies: [
                "TitanFirebaseCore",
                .product(name: "TitanAnalytics", package: titanKit),
                .product(name: "FirebaseAnalytics", package: firebase),
                .product(name: "FirebaseCrashlytics", package: firebase),
            ]
        ),
        .target(
            name: "TitanFirebaseRemoteConfig",
            dependencies: [
                "TitanFirebaseCore",
                .product(name: "TitanRemoteConfig", package: titanKit),
                .product(name: "FirebaseRemoteConfig", package: firebase),
            ]
        ),
    ],
    // The Firebase SDK isn't annotated for Swift 6 concurrency yet.
    swiftLanguageModes: [.v5]
)
