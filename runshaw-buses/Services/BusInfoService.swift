import Foundation
import Combine

class BusInfoService: BusInfoServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let keychainService: KeychainServiceProtocol
    
    init(networkService: NetworkServiceProtocol, keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.networkService = networkService
        self.keychainService = keychainService
    }
    
    func getBusInfo() -> AnyPublisher<BusInfoResponse, NetworkError> {
        // Get the auth token from keychain
        guard let token = keychainService.getAuthToken() else {
            return Fail(error: NetworkError.unauthorized).eraseToAnyPublisher()
        }

        // Make the network request
        return networkService.request(
            endpoint: "api/v2/businfo",
            method: .get,
            authType: .bearer
        )
    }
}

// MARK: - Factory Method

extension BusInfoService {
    static func create() -> BusInfoServiceProtocol {
        return BusInfoService(
            networkService: NetworkService.create()
        )
    }
}

#if DEBUG
class MockBusInfoService: BusInfoServiceProtocol {
    var mockBusInfoResponse: Result<BusInfoResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    
    func getBusInfo() -> AnyPublisher<BusInfoResponse, NetworkError> {
        return mockBusInfoResponse.publisher.eraseToAnyPublisher()
    }
    
    /// Set a mock bus info response with specific bus data
    func setMockBusInfo(busData: [String: BusData], lastUpdated: String? = nil, status: String = "OK") {
        let response = BusInfoResponse(
            busData: busData,
            lastUpdated: lastUpdated ?? ISO8601DateFormatter().string(from: Date()),
            status: status
        )
        mockBusInfoResponse = .success(response)
    }
    
    func setMockSampleBusInfo() {
        let sampleBusData: [String: BusData] = [
            "Bus1": BusData(status: "On Time", bay: "A", id: 1),
            "Bus2": BusData(status: "Delayed", bay: "B", id: 2),
            "Bus3": BusData(status: "Departed", bay: "C", id: 3)
        ]
        
        setMockBusInfo(busData: sampleBusData)
    }
    
    /// Set a mock error response
    func setMockError(_ error: NetworkError) {
        mockBusInfoResponse = .failure(error)
    }
}
#endif
