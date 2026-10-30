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
            // The version people see, and the build number fastlane raises for each upload.
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "1",
            "DEVELOPMENT_TEAM": "",
            // Dolingo.entitlements (Sign in with Apple) unless Secrets.xcconfig empties it, as a
            // free Personal Team must: those teams can't sign Sign in with Apple.
            "CODE_SIGN_ENTITLEMENTS": "$(DOLINGO_ENTITLEMENTS)",
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
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "UILaunchScreen": [:],
                "TitanAppEnvironment": "$(APP_ENV)",
                "TitanAPIBaseURL": "$(API_BASE_URL)",
                "DolingoAIBaseURL": "$(AI_BASE_URL)",
                "DolingoAIClientKey": "$(AI_CLIENT_KEY)",
                "DolingoLegalBaseURL": "$(LEGAL_BASE_URL)",
                // Only HTTPS and Apple's own encryption: exempt, so no export compliance questions.
                "ITSAppUsesNonExemptEncryption": false,
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
