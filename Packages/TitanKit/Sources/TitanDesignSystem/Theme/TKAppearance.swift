import SwiftUI

/// Light, dark or follow the device: the "Theme" choice on the settings screen.
/// Store it in the app's preferences and apply it at the root:
///
///     RootView()
///         .tkAppearance(appearance)
public enum TKAppearance: String, Codable, CaseIterable, Sendable {
    case system, light, dark

    /// nil lets the device decide.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

public extension View {
    func tkAppearance(_ appearance: TKAppearance) -> some View {
        preferredColorScheme(appearance.colorScheme)
    }
}
