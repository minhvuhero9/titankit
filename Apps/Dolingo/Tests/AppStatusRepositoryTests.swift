import XCTest
import TitanCore
import TitanNetworking
@testable import Dolingo

final class AppStatusRepositoryTests: XCTestCase {
    func testFetchesStatusThroughAPIClient() async throws {
        let api = MockAPIClient()
        api.stub(GetAppStatus.self, with: .success(AppStatus(minimumVersion: "1.0.0", isUnderMaintenance: false)))

        let status = try await AppStatusRepository(api: api).fetch()

        XCTAssertEqual(status.minimumVersion, "1.0.0")
        XCTAssertEqual(api.sentPaths, ["/v1/app-status"])
    }

    func testPassesTitanErrorThrough() async {
        let api = MockAPIClient()
        api.stub(GetAppStatus.self, with: .failure(.network(.offline)))

        do {
            _ = try await AppStatusRepository(api: api).fetch()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error, .network(.offline))
        }
    }

    @MainActor
    func testPreviewContainerUsesMocks() {
        let container = AppContainer.preview()
        XCTAssertTrue(container.api is MockAPIClient)
        XCTAssertTrue(container.networkMonitor.isOnline)
    }
}
