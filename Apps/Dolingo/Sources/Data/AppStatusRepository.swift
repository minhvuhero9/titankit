import Foundation
import TitanCore
import TitanNetworking

/// Sample of the Repository pattern on top of TitanNetworking.
/// The real endpoint arrives with the backend; until then tests drive it through MockAPIClient.
struct AppStatus: Decodable, Equatable, Sendable {
    let minimumVersion: String
    let isUnderMaintenance: Bool
}

struct GetAppStatus: Endpoint {
    typealias Response = AppStatus
    var path: String { "/v1/app-status" }
    var requiresAuth: Bool { false }
}

struct AppStatusRepository: Sendable {
    let api: any APIClient

    func fetch() async throws(TitanError) -> AppStatus {
        try await api.send(GetAppStatus())
    }
}
