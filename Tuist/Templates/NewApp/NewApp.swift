import ProjectDescription

// A new app on TitanKit, ready to generate and run:
//
//     tuist scaffold NewApp --name Lingo --company titanstudio
//     cp Apps/Lingo/Config/Secrets.example.xcconfig Apps/Lingo/Config/Secrets.xcconfig
//     tuist install && tuist generate
//
// It makes Apps/<name> with Dev, Staging and Prod, the kit wired through an AppContainer, a
// theme to fill in from Figma, Vietnamese and English strings, a privacy manifest and tests.
// See docs/modules/Tooling.md.

let name: Template.Attribute = .required("name")
let company: Template.Attribute = .optional("company", default: .string("titanstudio"))

let app = "Apps/\(name)"

let template = Template(
    description: "A new app on TitanKit with Dev, Staging and Prod",
    attributes: [name, company],
    items: [
        .file(path: "\(app)/Project.swift", templatePath: "Project.stencil"),
        .file(path: "\(app)/Config/Shared.xcconfig", templatePath: "Config/Shared.stencil"),
        .file(path: "\(app)/Config/Dev.xcconfig", templatePath: "Config/Dev.stencil"),
        .file(path: "\(app)/Config/Staging.xcconfig", templatePath: "Config/Staging.stencil"),
        .file(path: "\(app)/Config/Prod.xcconfig", templatePath: "Config/Prod.stencil"),
        .file(path: "\(app)/Config/Secrets.example.xcconfig", templatePath: "Config/Secrets.example.stencil"),
        .file(path: "\(app)/Sources/\(name)App.swift", templatePath: "Sources/App.stencil"),
        .file(path: "\(app)/Sources/AppConfig.swift", templatePath: "Sources/AppConfig.stencil"),
        .file(path: "\(app)/Sources/AppContainer.swift", templatePath: "Sources/AppContainer.stencil"),
        .file(path: "\(app)/Sources/RootView.swift", templatePath: "Sources/RootView.stencil"),
        .file(path: "\(app)/Sources/HomeScreen.swift", templatePath: "Sources/HomeScreen.stencil"),
        .file(path: "\(app)/Sources/Theme/\(name)Theme.swift", templatePath: "Sources/Theme.stencil"),
        .file(path: "\(app)/Resources/Localizable.xcstrings", templatePath: "Resources/Localizable.stencil"),
        .file(path: "\(app)/Resources/PrivacyInfo.xcprivacy", templatePath: "Resources/PrivacyInfo.stencil"),
        .file(path: "\(app)/Resources/Assets.xcassets/Contents.json", templatePath: "Resources/AssetsContents.stencil"),
        .file(path: "\(app)/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json", templatePath: "Resources/AppIcon.stencil"),
        .file(path: "\(app)/Tests/AppConfigTests.swift", templatePath: "Tests/AppConfigTests.stencil"),
    ]
)
