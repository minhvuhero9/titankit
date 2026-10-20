import Combine
import Network

/// Publishes whether the device is online, so the root view can show an offline screen.
@MainActor
public final class NetworkMonitor: ObservableObject {
    @Published public private(set) var isOnline: Bool

    private let observer: PathObserver?

    /// Pass `startMonitoring: false` in tests and previews to get a fixed state.
    public init(startMonitoring: Bool = true, isOnline: Bool = true) {
        self.isOnline = isOnline
        guard startMonitoring else {
            observer = nil
            return
        }
        let observer = PathObserver()
        self.observer = observer
        observer.start { [weak self] online in
            Task { @MainActor [weak self] in self?.isOnline = online }
        }
    }
}

/// Owns the NWPathMonitor and cancels it when released.
private final class PathObserver: @unchecked Sendable {
    // @unchecked: NWPathMonitor is thread-safe and only touched from start and deinit.
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "titan.network-monitor")

    func start(onChange: @escaping @Sendable (Bool) -> Void) {
        monitor.pathUpdateHandler = { @Sendable path in
            onChange(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
