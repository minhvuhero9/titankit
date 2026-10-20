import Foundation

/// Parses incoming URLs and hands the result to the app, which decides where it opens.
///
///     .onOpenURL { container.deepLinks.handle($0) }
@MainActor
public final class DeepLinkHandler<Parser: DeepLinkParser> {
    private let parser: Parser
    private let onLink: @MainActor (DeepLink<Parser.Route>) -> Void

    public init(parser: Parser, onLink: @escaping @MainActor (DeepLink<Parser.Route>) -> Void) {
        self.parser = parser
        self.onLink = onLink
    }

    /// Returns false when the parser does not understand the URL.
    @discardableResult
    public func handle(_ url: URL) -> Bool {
        guard let link = parser.link(from: url) else { return false }
        onLink(link)
        return true
    }
}
