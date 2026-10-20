/// A screen an app can navigate to. Usually an enum with one case per screen:
///
///     enum AppRoute: Routable {
///         case lessonDetail(id: String)
///         case settings
///     }
public protocol Routable: Hashable, Identifiable, Sendable {}

public extension Routable {
    var id: Self { self }
}
