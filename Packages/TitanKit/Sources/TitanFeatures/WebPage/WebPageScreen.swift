import SwiftUI
import TitanCore
import TitanDesignSystem
import WebKit

/// Shows a web page inside the app, e.g. Privacy Policy and Terms of Service.
/// While loading it shows a spinner; when the page fails it shows the error and a retry button.
///
///     WebPageScreen(title: Text.kit(KitStrings.Settings.privacy, locale: locale),
///                   url: AppConfig.privacyURL, onBack: { router.pop() })
public struct WebPageScreen: View {
    private let title: Text
    private let url: URL
    private let onBack: (() -> Void)?

    @State private var isLoading = true
    @State private var error: TitanError?
    @State private var reloadCount = 0
    @Environment(\.theme) private var theme

    public init(title: Text, url: URL, onBack: (() -> Void)? = nil) {
        self.title = title
        self.url = url
        self.onBack = onBack
    }

    /// The error to show for a failed load, or nil when it should be ignored
    /// (a load cancelled because another one started).
    public nonisolated static func titanError(for error: Error) -> TitanError? {
        guard let urlError = error as? URLError else {
            return (error as NSError).code == NSURLErrorCancelled ? nil : .unknown(error.localizedDescription)
        }
        switch urlError.code {
        case .cancelled: return nil
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .network(.offline)
        case .timedOut: return .network(.timeout)
        case .badServerResponse: return .network(.server(statusCode: 0))
        default: return .unknown(urlError.localizedDescription)
        }
    }

    public var body: some View {
        WebView(url: url, reloadCount: reloadCount) { state in
            switch state {
            case .loading:
                isLoading = true
                error = nil
            case .loaded:
                isLoading = false
            case let .failed(failure):
                isLoading = false
                error = Self.titanError(for: failure)
            }
        }
        .opacity(error == nil ? 1 : 0)
        .overlay {
            if let error {
                TKErrorView(error: error) { reloadCount += 1 }
            } else if isLoading {
                ProgressView().controlSize(.large).tint(theme.colors.actionPrimary.color)
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: title, onBack: onBack)
    }
}

private struct WebView: UIViewRepresentable {
    enum LoadState {
        case loading, loaded
        case failed(Error)
    }

    let url: URL
    let reloadCount: Int
    let onState: (LoadState) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onState: onState)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = false
        context.coordinator.loadedReloadCount = reloadCount
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onState = onState
        if context.coordinator.loadedReloadCount != reloadCount {
            context.coordinator.loadedReloadCount = reloadCount
            webView.load(URLRequest(url: url))
        }
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var onState: (LoadState) -> Void
        var loadedReloadCount = 0

        init(onState: @escaping (LoadState) -> Void) {
            self.onState = onState
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onState(.loading)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onState(.loaded)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onState(.failed(error))
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onState(.failed(error))
        }
    }
}
