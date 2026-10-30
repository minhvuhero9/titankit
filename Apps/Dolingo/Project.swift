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
// `TUIST_PERSONAL_TEAM=1 tuist generate` builds for a free Apple ID (Personal Team), which can't
// sign Sign in with Apple or In-App Purchase. Firebase Analytics links StoreKit.framework, which
// makes Xcode ask for In-App Purchase, so it is left out (with Crashlytics), along with the
// entitlements. StoreKit itself still works with Dolingo.storekit.
let personalTeam = Environment.personalTeam.getBoolean(default: false)

let firebaseModules = [
    "TitanFirebaseCore", "TitanFirebaseAuth", "TitanFirebaseRemoteConfig",
] + (personalTeam ? [] : ["TitanFirebaseAnalytics"])

var baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    // The version people see, and the build number fastlane raises for each upload.
    "MARKETING_VERSION": "1.0.0",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "",
    // Dolingo.entitlements (Sign in with Apple), except for a Personal Team (see above).
    "CODE_SIGN_ENTITLEMENTS": personalTeam ? "" : "$(DOLINGO_ENTITLEMENTS)",
    // Firebase's static libraries register their Objective-C categories only with -ObjC.
    "OTHER_LDFLAGS": "$(inherited) -ObjC",
]
if personalTeam {
    baseSettings["OTHER_SWIFT_FLAGS"] = "$(inherited) -DPERSONAL_TEAM"
}

let project = Project(
    name: appName,
    settings: .settings(
        base: baseSettings,
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
            dependencies: [.target(name: appName)] + kitModules.map { .external(name: $0) }
        ),
        // App Store screenshots (Tools/screenshots.sh): launches the app in ScreenshotMode.
        .target(
            name: "\(appName)UITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "\(bundlePrefix).dolingo.uitests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["UITests/**"],
            dependencies: [.target(name: appName)]
        ),
    ],
    schemes: ["Dev", "Staging", "Prod"].map { env in
        .scheme(
            name: "\(appName)-\(env)",
            shared: true,
            buildAction: .buildAction(targets: [.target(appName)]),
            testAction: .targets(["\(appName)Tests"], configuration: .configuration(env)),
            // Dev buys from Dolingo.storekit inside Xcode; Staging and Prod use the App Store sandbox.
            runAction: .runAction(
                configuration: .configuration(env),
                options: env == "Dev" ? .options(storeKitConfigurationPath: "Dolingo.storekit") : .options()
            ),
            archiveAction: .archiveAction(configuration: .configuration(env))
        )
    } + [
        .scheme(
            name: "\(appName)-Screenshots",
            shared: true,
            buildAction: .buildAction(targets: [.target(appName), .target("\(appName)UITests")]),
            testAction: .targets(["\(appName)UITests"], configuration: .configuration("Dev"))
        ),
    ],
    additionalFiles: ["Dolingo.storekit"]
)
