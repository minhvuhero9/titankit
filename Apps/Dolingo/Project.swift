import ProjectDescription

// Working name from the purchased Figma template; rename before release.
let appName = "Dolingo"
let bundlePrefix = "com.titanstudio"

let kitModules = [
    "TitanCore", "TitanNetworking", "TitanStorage",
    "TitanIcons", "TitanDesignSystem", "TitanNavigation", "TitanLocalization", "TitanAuth", "TitanRemoteConfig",
    "TitanFeatures",
]

let project = Project(
    name: appName,
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "DEVELOPMENT_TEAM": "",
        ],
        configurations: [
            .debug(name: "Dev", xcconfig: "Config/Dev.xcconfig"),
            .release(name: "Staging", xcconfig: "Config/Staging.xcconfig"),
            .release(name: "Prod", xcconfig: "Config/Prod.xcconfig"),
        ]
    ),
    targets: [
        .target(
            name: appName,
            destinations: [.iPhone],
            product: .app,
            bundleId: "\(bundlePrefix).dolingo$(BUNDLE_ID_SUFFIX)",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
                "UILaunchScreen": [:],
                "TitanAppEnvironment": "$(APP_ENV)",
                "TitanAPIBaseURL": "$(API_BASE_URL)",
                "CFBundleDevelopmentRegion": "vi",
                "CFBundleLocalizations": ["vi", "en"],
                "CFBundleURLTypes": [
                    ["CFBundleURLName": "\(bundlePrefix).dolingo", "CFBundleURLSchemes": ["dolingo"]],
                ],
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: kitModules.map { .external(name: $0) }
        ),
        .target(
            name: "\(appName)Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(bundlePrefix).dolingo.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: appName)] + ["TitanCore", "TitanNetworking", "TitanStorage", "TitanDesignSystem", "TitanNavigation", "TitanLocalization", "TitanAuth", "TitanRemoteConfig", "TitanFeatures"].map { .external(name: $0) }
        ),
    ],
    schemes: ["Dev", "Staging", "Prod"].map { env in
        .scheme(
            name: "\(appName)-\(env)",
            shared: true,
            buildAction: .buildAction(targets: [.target(appName)]),
            testAction: .targets(["\(appName)Tests"], configuration: .configuration(env)),
            runAction: .runAction(configuration: .configuration(env)),
            archiveAction: .archiveAction(configuration: .configuration(env))
        )
    }
)
