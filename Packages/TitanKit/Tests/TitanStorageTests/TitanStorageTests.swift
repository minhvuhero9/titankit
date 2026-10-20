import XCTest
import TitanCore
@testable import TitanStorage

private extension PreferenceKey where Value == Bool {
    static let seenOnboarding = PreferenceKey("test.seenOnboarding", default: false)
}

private extension PreferenceKey where Value == [String] {
    static let recentSearches = PreferenceKey("test.recentSearches", default: [])
}

private struct Draft: Codable, Equatable, Sendable {
    let title: String
}

final class PreferencesTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "TitanStorageTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testReturnsDefaultUntilSet() {
        let preferences = Preferences(defaults: defaults)
        XCTAssertFalse(preferences.value(.seenOnboarding))

        preferences.set(true, for: .seenOnboarding)
        XCTAssertTrue(preferences.value(.seenOnboarding))

        preferences.reset(.seenOnboarding)
        XCTAssertFalse(preferences.value(.seenOnboarding))
    }

    func testStoresCodableValues() {
        let preferences = Preferences(defaults: defaults)
        preferences.set(["swift", "ios"], for: .recentSearches)
        XCTAssertEqual(preferences.value(.recentSearches), ["swift", "ios"])
    }

    @MainActor
    func testPropertyWrapperSharesStorageWithPreferences() {
        let wrapper = Preference(.seenOnboarding, store: defaults)
        XCTAssertFalse(wrapper.wrappedValue)

        Preferences(defaults: defaults).set(true, for: .seenOnboarding)
        XCTAssertTrue(wrapper.wrappedValue)
    }
}

final class SecureStoreTests: XCTestCase {
    // KeychainStore needs a signed host app; the in-memory store covers the protocol contract.
    func testInMemoryStoreRoundTrip() throws {
        let store = InMemorySecureStore()
        try store.setString("abc", for: "token")
        XCTAssertEqual(try store.string(for: "token"), "abc")

        try store.remove("token")
        XCTAssertNil(try store.data(for: "token"))
    }
}

final class DataCacheTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testFileCacheRoundTrip() async throws {
        let cache = FileCache(folder: "test", baseDirectory: directory)
        try await cache.save(Draft(title: "Hello"), for: "draft/1", ttl: nil)

        let loaded = try await cache.load(Draft.self, for: "draft/1")
        XCTAssertEqual(loaded, Draft(title: "Hello"))
    }

    func testFileCacheExpiredEntryReturnsNil() async throws {
        let cache = FileCache(folder: "test", baseDirectory: directory)
        try await cache.save(Draft(title: "Old"), for: "draft", ttl: .zero)

        let loaded = try await cache.load(Draft.self, for: "draft")
        XCTAssertNil(loaded)
    }

    func testFileCacheClear() async throws {
        let cache = FileCache(folder: "test", baseDirectory: directory)
        try await cache.save(Draft(title: "A"), for: "a", ttl: nil)
        await cache.clear()

        let loaded = try await cache.load(Draft.self, for: "a")
        XCTAssertNil(loaded)
    }

    func testInMemoryCacheMatchesFileCacheRules() async throws {
        let cache = InMemoryDataCache()
        try await cache.save(Draft(title: "A"), for: "a", ttl: .seconds(60))
        try await cache.save(Draft(title: "B"), for: "b", ttl: .zero)

        let a = try await cache.load(Draft.self, for: "a")
        let b = try await cache.load(Draft.self, for: "b")
        XCTAssertEqual(a, Draft(title: "A"))
        XCTAssertNil(b)
    }
}

final class ImageCacheTests: XCTestCase {
    func testMockImageCacheRecordsRequests() async throws {
        let cache = MockImageCache()
        let url = URL(string: "https://example.com/a.png")!
        _ = try await cache.image(for: url)
        XCTAssertEqual(cache.requestedURLs, [url])
    }
}
