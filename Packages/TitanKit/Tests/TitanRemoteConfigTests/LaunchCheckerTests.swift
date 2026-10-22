import XCTest
import TitanCore
@testable import TitanRemoteConfig

final class AppVersionTests: XCTestCase {
    func testComparesEachPartAsANumber() throws {
        XCTAssertLessThan(try XCTUnwrap(AppVersion("1.2.0")), try XCTUnwrap(AppVersion("1.10.0")))
        XCTAssertEqual(AppVersion("2.0"), AppVersion("2.0.0"))
        XCTAssertGreaterThan(try XCTUnwrap(AppVersion("2.0.1")), try XCTUnwrap(AppVersion("2")))
    }

    func testRejectsTextThatIsNotAVersion() {
        XCTAssertNil(AppVersion(""))
        XCTAssertNil(AppVersion("1.x"))
        XCTAssertNil(AppVersion("1..2"))
    }
}

final class RemoteConfigKeyTests: XCTestCase {
    private struct Banner: Decodable, Equatable, RemoteConfigValue {
        let title: String
    }

    func testMissingOrWrongValueGivesTheDefault() {
        let config = MockRemoteConfig(values: ["minimum_version": .bool(true)])
        XCTAssertEqual(config.value(for: .minimumVersion), "0.0.0")
        XCTAssertFalse(config.value(for: .maintenanceEnabled))
    }

    func testReadsBuiltInTypes() {
        let config = MockRemoteConfig(values: [
            "flag": .string("TRUE"), "count": .number(3), "ratio": .string("0.5"),
        ])
        XCTAssertTrue(config.value(for: RemoteConfigKey("flag", default: false)))
        XCTAssertEqual(config.value(for: RemoteConfigKey("count", default: 0)), 3)
        XCTAssertEqual(config.value(for: RemoteConfigKey("ratio", default: 0.0)), 0.5)
    }

    func testReadsDecodableFromJSONAndFallsBackWhenMalformed() {
        let fallback = Banner(title: "default")
        let key = RemoteConfigKey("banner", default: fallback)
        let config = MockRemoteConfig(values: ["banner": .string(#"{"title":"Sale"}"#)])
        XCTAssertEqual(config.value(for: key), Banner(title: "Sale"))
        config.set(.string("{not json"), for: "banner")
        XCTAssertEqual(config.value(for: key), fallback)
    }
}

final class LaunchCheckerTests: XCTestCase {
    private let store = URL(string: "https://apps.apple.com/app/id1")!

    private func check(_ config: MockRemoteConfig, appVersion: String = "1.2.0", timeout: Duration = .seconds(3)) async -> LaunchStatus {
        await LaunchChecker(config: config, appVersion: appVersion, storeURL: store, timeout: timeout).check()
    }

    func testOkByDefault() async {
        let config = MockRemoteConfig()
        let status = await check(config)
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(config.fetches, 1)
    }

    func testMaintenanceWinsOverUpdate() async {
        let config = MockRemoteConfig(values: [
            "maintenance_enabled": .bool(true),
            "maintenance_message": .string("Back at 10:00"),
            "minimum_version": .string("9.0.0"),
        ])
        let status = await check(config)
        XCTAssertEqual(status, .maintenance(message: "Back at 10:00"))
    }

    func testOlderVersionMustUpdate() async {
        let config = MockRemoteConfig(values: ["minimum_version": .string("1.10")])
        let older = await check(config, appVersion: "1.2.0")
        XCTAssertEqual(older, .forceUpdate(storeURL: store))
        let same = await check(config, appVersion: "1.10.0")
        XCTAssertEqual(same, .ok)
    }

    func testFailedFetchUsesActiveValues() async {
        let config = MockRemoteConfig(fetchError: .network(.offline))
        let status = await check(config)
        XCTAssertEqual(status, .ok)
    }

    func testSlowFetchDoesNotHoldTheSplash() async {
        let config = MockRemoteConfig(fetchDelay: .seconds(30))
        let clock = ContinuousClock()
        let start = clock.now
        let status = await check(config, timeout: .milliseconds(100))
        XCTAssertEqual(status, .ok)
        XCTAssertLessThan(clock.now - start, .seconds(5))
    }

    func testUnreadableVersionNeverForcesAnUpdate() {
        let status = LaunchChecker.status(maintenance: false, message: "", minimumVersion: "beta",
                                          appVersion: "1.0.0", storeURL: store)
        XCTAssertEqual(status, .ok)
    }
}
