import Combine
import Foundation

protocol BusInfoServiceProtocol {
    /// Fetch bus information
    func getBusInfo() -> AnyPublisher<BusInfoResponse, NetworkError>
    
    /// Fetch bus info map URL with token
    func getBusMapUrl() throws -> URL?
    
    /// Fetch list of available bus routes
    func getBusRoutes() -> AnyPublisher<[String], NetworkError>
}
