import Combine
import Foundation

protocol BusInfoServiceProtocol {
    /// Fetch bus information
    func getBusInfo() -> AnyPublisher<BusInfoResponse, NetworkError>
    
    /// Fetch bus info map URL with token
    func getBusMapUrl() throws -> URL?
}
