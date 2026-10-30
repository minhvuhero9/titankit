// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    // External packages get the same three configurations as the apps,
    // otherwise Xcode falls back to Debug/Release and settings drift.
    let packageSettings = PackageSettings(
        baseSettings: .settings(configurations: [
            .debug(name: "Dev"),
            .release(name: "Staging"),
            .release(name: "Prod"),
        ])
    )
#endif

let package = Package(
    name: "TitanKitDependencies",
    dependencies: [
        .package(path: "../Packages/TitanKit"),
        // Firebase behind the kit's protocols; only AppContainer imports it.
        .package(path: "../Adapters/TitanFirebase"),
    ]
)
