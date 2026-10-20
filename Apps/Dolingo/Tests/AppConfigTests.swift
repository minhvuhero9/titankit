import XCTest
import TitanCore
@testable import Dolingo

final class AppConfigTests: XCTestCase {
    func testReadsEnvironmentFromInfoPlist() {
        let config = AppConfig(infoDictionary: [
            "TitanAppEnvironment": "staging",
            "TitanAPIBaseURL": "https://api-staging.example.com",
        ])
        XCTAssertEqual(config.environment, .staging)
        XCTAssertEqual(config.apiBaseURL.host, "api-staging.example.com")
    }

    func testUnknownEnvironmentFallsBackToDev() {
        let config = AppConfig(infoDictionary: ["TitanAppEnvironment": "bogus"])
        XCTAssertEqual(config.environment, .dev)
    }
}
