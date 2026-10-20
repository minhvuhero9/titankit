import SwiftUI
import TitanCore

/// Picks the right view for a LoadState: spinner, content, empty state or error with retry.
///
///     TKAsyncContent(vm.state, isEmpty: \.isEmpty, empty: TKEmptyState(...), retry: vm.reload) { items in
///         List(items) { ... }
///     }
public struct TKAsyncContent<Value, Content: View>: View {
    private let state: LoadState<Value>
    private let isEmpty: (Value) -> Bool
    private let empty: TKEmptyState?
    private let retry: (() -> Void)?
    private let content: (Value) -> Content

    public init(
        _ state: LoadState<Value>,
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        empty: TKEmptyState? = nil,
        retry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.isEmpty = isEmpty
        self.empty = empty
        self.retry = retry
        self.content = content
    }

    public var body: some View {
        switch state {
        case .idle, .loading:
            TKLoadingView()
        case let .loaded(value):
            if let empty, isEmpty(value) {
                empty
            } else {
                content(value)
            }
        case let .failed(error):
            TKErrorView(error: error, retry: retry)
        }
    }
}
