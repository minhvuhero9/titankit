import SwiftUI
import TitanCore
import UIKit

/// Loads and caches remote images. Swap the implementation (Nuke, Kingfisher...) without touching views.
public protocol ImageCache: Sendable {
    func image(for url: URL) async throws(TitanError) -> UIImage
    func prefetch(_ urls: [URL])
    func clearMemory()
}

/// Default cache with no third-party code: NSCache in memory, URLCache on disk.
public final class URLSessionImageCache: ImageCache, @unchecked Sendable {
    // @unchecked: NSCache and URLSession are thread-safe; nothing else is mutable.
    public static let shared = URLSessionImageCache()

    private let memory = NSCache<NSURL, UIImage>()
    private let session: URLSession

    public init(memoryLimitMB: Int = 100, diskLimitMB: Int = 200) {
        memory.totalCostLimit = memoryLimitMB * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 0,
            diskCapacity: diskLimitMB * 1024 * 1024,
            directory: nil
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
    }

    public func image(for url: URL) async throws(TitanError) -> UIImage {
        if let cached = memory.object(forKey: url as NSURL) { return cached }

        let data: Data
        do {
            data = try await session.data(from: url).0
        } catch {
            throw Self.map(error)
        }
        guard let image = UIImage(data: data) else {
            throw .decoding("Not an image: \(url.lastPathComponent)")
        }
        memory.setObject(image, forKey: url as NSURL, cost: data.count)
        return image
    }

    public func prefetch(_ urls: [URL]) {
        for url in urls {
            Task { _ = try? await image(for: url) }
        }
    }

    public func clearMemory() {
        memory.removeAllObjects()
    }

    private static func map(_ error: any Error) -> TitanError {
        if error is CancellationError { return .cancelled }
        guard let code = (error as? URLError)?.code else { return .unknown(error.localizedDescription) }
        switch code {
        case .cancelled: return .cancelled
        case .timedOut: return .network(.timeout)
        case .notConnectedToInternet, .networkConnectionLost: return .network(.offline)
        default: return .unknown(error.localizedDescription)
        }
    }
}

private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: any ImageCache = URLSessionImageCache.shared
}

public extension EnvironmentValues {
    var imageCache: any ImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
