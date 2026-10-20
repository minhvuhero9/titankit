/// State of anything a screen loads: drives loading, content and error views.
public enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(TitanError)

    public var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    public var error: TitanError? {
        if case let .failed(error) = self { return error }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension LoadState: Equatable where Value: Equatable {}
extension LoadState: Sendable where Value: Sendable {}
