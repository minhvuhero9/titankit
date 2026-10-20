import XCTest
@testable import TitanCore

final class TitanErrorTests: XCTestCase {
    func testRetryableOnlyForNetwork() {
        XCTAssertTrue(TitanError.network(.timeout).isRetryable)
        XCTAssertTrue(TitanError.network(.offline).isRetryable)
        XCTAssertTrue(TitanError.network(.server(statusCode: 503)).isRetryable)
        XCTAssertFalse(TitanError.unauthorized.isRetryable)
        XCTAssertFalse(TitanError.decoding("x").isRetryable)
        XCTAssertFalse(TitanError.cancelled.isRetryable)
    }

    func testEveryCaseHasAUserMessage() {
        let all: [TitanError] = [
            .network(.offline), .network(.timeout), .network(.server(statusCode: 500)),
            .unauthorized, .decoding("x"), .notFound, .storage("x"), .cancelled, .unknown("x"),
        ]
        for error in all {
            XCTAssertFalse(error.userMessage.isEmpty, "\(error)")
        }
    }
}

final class AppEnvironmentTests: XCTestCase {
    func testReadsInfoDictionary() {
        XCTAssertEqual(AppEnvironment(infoDictionary: ["TitanAppEnvironment": "staging"]), .staging)
        XCTAssertEqual(AppEnvironment(infoDictionary: ["TitanAppEnvironment": "prod"]), .prod)
    }

    func testUnknownOrMissingFallsBackToDev() {
        XCTAssertEqual(AppEnvironment(infoDictionary: ["TitanAppEnvironment": "bogus"]), .dev)
        XCTAssertEqual(AppEnvironment(infoDictionary: [:]), .dev)
    }

    func testOnlyProdIsProduction() {
        XCTAssertTrue(AppEnvironment.prod.isProduction)
        XCTAssertFalse(AppEnvironment.staging.isProduction)
        XCTAssertEqual(AppEnvironment.prod.defaultLogLevel, .warning)
        XCTAssertEqual(AppEnvironment.dev.defaultLogLevel, .debug)
    }
}

final class LoggingTests: XCTestCase {
    func testMockLoggerRecordsLevelAndMessage() {
        let logger = MockLogger()
        logger.info("hello")
        logger.error("boom")
        XCTAssertEqual(logger.entries, [
            .init(level: .info, message: "hello"),
            .init(level: .error, message: "boom"),
        ])
    }

    func testLevelsAreOrdered() {
        XCTAssertLessThan(LogLevel.debug, .info)
        XCTAssertLessThan(LogLevel.warning, .error)
    }
}

final class LoadStateTests: XCTestCase {
    func testAccessors() {
        XCTAssertEqual(LoadState.loaded(3).value, 3)
        XCTAssertNil(LoadState<Int>.loading.value)
        XCTAssertTrue(LoadState<Int>.loading.isLoading)
        XCTAssertEqual(LoadState<Int>.failed(.notFound).error, .notFound)
    }
}

final class ExtensionTests: XCTestCase {
    func testSafeSubscript() {
        let items = [1, 2, 3]
        XCTAssertEqual(items[safe: 1], 2)
        XCTAssertNil(items[safe: 5])
    }

    func testBlankStrings() {
        XCTAssertTrue("  \n".isBlank)
        XCTAssertFalse(" a ".isBlank)
        XCTAssertEqual(" a ".nilIfBlank, "a")
        XCTAssertNil("   ".nilIfBlank)
    }

    func testDurationToTimeInterval() {
        XCTAssertEqual(Duration.milliseconds(1500).timeInterval, 1.5, accuracy: 0.0001)
    }
}
