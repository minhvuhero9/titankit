import SwiftUI

/// Marker for an app's Composition Root (AppContainer).
/// Views receive it through the environment instead of creating services themselves.
public protocol DependencyContainer: AnyObject, Sendable {}

private struct ContainerKey: EnvironmentKey {
    static let defaultValue: (any DependencyContainer)? = nil
}

private struct LoggerKey: EnvironmentKey {
    static let defaultValue: any Logging = NoopLogger()
}

public extension EnvironmentValues {
    var container: (any DependencyContainer)? {
        get { self[ContainerKey.self] }
        set { self[ContainerKey.self] = newValue }
    }

    var logger: any Logging {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}
