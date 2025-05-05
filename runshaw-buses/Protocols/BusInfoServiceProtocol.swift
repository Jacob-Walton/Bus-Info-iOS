import Combine

protocol BusInfoServiceProtocol {
    /// Fetch bus information
    func getBusInfo() -> AnyPublisher<BusInfoResponse, NetworkError>
}
