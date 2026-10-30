import ProjectDescription

// Working name from the purchased Figma template; rename before release.
let appName = "Dolingo"
let bundlePrefix = "com.titanstudio"

let kitModules = [
    "TitanCore", "TitanNetworking", "TitanStorage",
    "TitanIcons", "TitanDesignSystem", "TitanNavigation", "TitanLocalization", "TitanAuth", "TitanRemoteConfig",
    "TitanPurchase", "TitanSpeech", "TitanPush", "TitanAI", "TitanAnalytics", "TitanFeatures",
]

// Used when Config/Secrets.xcconfig and Resources/Firebase/GoogleService-Info-<Env>.plist exist;
// otherwise the app runs on the kit's mocks.
let firebaseModules = [
    "TitanFirebaseCore", "TitanFirebaseAuth", "TitanFirebaseAnalytics", "TitanFirebaseRemoteConfig",
]

let project = Project(
    name: appName,
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "DEVELOPMENT_TEAM": "",
            // Firebase's static libraries register their Objective-C categories only with -ObjC.
            "OTHER_LDFLAGS": "$(inherited) -ObjC",
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
                "DolingoAIBaseURL": "$(AI_BASE_URL)",
                "DolingoAIClientKey": "$(AI_CLIENT_KEY)",
                "CFBundleDevelopmentRegion": "vi",
                "CFBundleLocalizations": ["vi", "en"],
                // Speaking practice in lessons (TitanSpeech).
                "NSMicrophoneUsageDescription": "Dolingo listens while you practise speaking so it can score your pronunciation.",
                "NSSpeechRecognitionUsageDescription": "Dolingo turns your speech into text to check your pronunciation.",
                "CFBundleURLTypes": [
                    ["CFBundleURLName": "\(bundlePrefix).dolingo", "CFBundleURLSchemes": ["dolingo"]],
                    // Google Sign-In returns here; REVERSED_CLIENT_ID from GoogleService-Info.
                    ["CFBundleURLName": "google", "CFBundleURLSchemes": ["$(GOOGLE_REVERSED_CLIENT_ID)"]],
                ],
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: .file(path: "Dolingo.entitlements"),
            dependencies: (kitModules + firebaseModules).map { .external(name: $0) }
        ),
        .target(
            name: "\(appName)Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(bundlePrefix).dolingo.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: appName)] + ["TitanCore", "TitanNetworking", "TitanStorage", "TitanDesignSystem", "TitanNavigation", "TitanLocalization", "TitanAuth", "TitanRemoteConfig", "TitanPurchase", "TitanSpeech", "TitanPush", "TitanAI", "TitanAnalytics", "TitanFeatures"].map { .external(name: $0) }
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
