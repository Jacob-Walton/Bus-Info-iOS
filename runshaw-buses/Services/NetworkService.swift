import Foundation
import Combine

// MARK: - Default Method Extensions
extension NetworkServiceProtocol {
    /// Simplified request method with default parameters
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        authType: AuthType = .bearer
    ) -> AnyPublisher<T, NetworkError> {
        return request(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: headers,
            queryItems: queryItems,
            authType: authType
        )
    }
}

// MARK: - Network Service Implementation

class NetworkService: NetworkServiceProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let timeoutInterval: TimeInterval
    private let keychainService: KeychainServiceProtocol

    init(baseURL: URL, 
         timeout: TimeInterval = 30.0, 
         session: URLSession = .shared,
         keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.baseURL = baseURL
        self.timeoutInterval = timeout
        self.session = session
        self.keychainService = keychainService

        // Configure JSON decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
    }

    convenience init(baseURL: String, 
                    timeout: TimeInterval = 30.0, 
                    session: URLSession = .shared,
                    keychainService: KeychainServiceProtocol = KeychainService.shared) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.init(baseURL: url, timeout: timeout, session: session, keychainService: keychainService)
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        authType: AuthType = .bearer
    ) -> AnyPublisher<T, NetworkError> {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval

        // Apply default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Apply authentication based on auth type
        if let token = keychainService.getAuthToken(), !endpoint.contains("login") {
            switch authType {
                case .bearer:
                // Standard bearer token authentication
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                #if DEBUG
                print("Using Bearer token for authentication: \(token.prefix(8))...")
                #endif

                case .apiKey:
                // Placeholder for future API key authentication
                request.addValue(token, forHTTPHeaderField: "X-API-Key")
                #if DEBUG
                print("Using API key for authentication: \(token.prefix(8))...")
                #endif
                
                case .none:
                // No authentication required
                #if DEBUG
                print("No authentication required for this request.")
                #endif
                break
            }
        }

        // Apply additional headers
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

        request.httpBody = body

        #if DEBUG
        print("Request URL: \(url.absoluteString)")
        print("Request Method: \(method.rawValue)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        #endif

        return session.dataTaskPublisher(for: request).tryMap { data, response in
            #if DEBUG
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("Response JSON: \(json)")
            }
            #endif

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpStatusCode(httpResponse.statusCode)
            }

            return data
        }
        .decode(type: T.self, decoder: self.jsonDecoder)
        .mapError { error in
            if let decodingError = error as? DecodingError {
                #if DEBUG
                print("Decoding error: \(decodingError)")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key: '\(key)' not found: \(context)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value of type \(type) not found: \(context.debugDescription)")
                default:
                    print("Other decoding error: \(decodingError)")
                }
                #endif
                return NetworkError.decodingError(decodingError)
            } else if let networkError = error as? NetworkError {
                return networkError
            } else if let urlError = error as? URLError {
                return NetworkError.unexpectedError(urlError)
            } else {
                return NetworkError.unexpectedError(error)
            }
        }
        .eraseToAnyPublisher()
    }
}

/// MARK: - Method for Configuration

extension NetworkService {
    /// Create a network service with environment configuration
    static func create() -> NetworkServiceProtocol {
        return NetworkService(
            baseURL: ConfigurationManager.shared.currentConfig.baseURL,
            timeout: ConfigurationManager.shared.currentConfig.apiTimeout,
            keychainService: KeychainService.shared
        )
    }
}

// MARK: - Mock Network Service

#if DEBUG
class MockNetworkService: NetworkServiceProtocol {
    /// Map of endpoint to mock response
    var mockResponses: [String: Result<Data, NetworkError>] = [:]
    let keychainService: KeychainServiceProtocol
    
    init(keychainService: KeychainServiceProtocol = MockKeychainService()) {
        self.keychainService = keychainService
    }

    /// Set a mock response for a specific endpoint
    func setMockResponse<T: Encodable>(for endpoint: String, result: Result<T, NetworkError>) {
        switch result {
            case .success(let value):
                if let data = try? JSONEncoder().encode(value) {
                    mockResponses[endpoint] = .success(data)
                } else {
                mockResponses[endpoint] = .failure(.decodingError(NSError(domain: "MockNetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode mock response"])))
                }
            case .failure(let error):
                mockResponses[endpoint] = .failure(error)
        }
    }

    /// Set a raw data response for a specific endpoint
    func setMockDataResponse(for endpoint: String, data: Data) {
        mockResponses[endpoint] = .success(data)
    }

    /// Set an error response for a specific endpoint
    func setMockErrorResponse(for endpoint: String, error: NetworkError) {
        mockResponses[endpoint] = .failure(error)
    }

    /// Clear all mock responses
    func clearMockResponses() {
        mockResponses.removeAll()
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        authType: AuthType = .bearer
    ) -> AnyPublisher<T, NetworkError> {
        // Find the mock response for the endpoint
        let endpointKey = findMatchingEndpoint(for: endpoint)
        
        guard let endpointKey = endpointKey,
              let mockResult = mockResponses[endpointKey] else {
            return Fail(error: NetworkError.unexpectedError(NSError(domain: "MockNetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock response found for endpoint: \(endpoint)"]))).eraseToAnyPublisher()
        }
        
        switch mockResult {
        case .success(let data):
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return Just(decodedResponse)
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: NetworkError.decodingError(error)).eraseToAnyPublisher()
            }
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    /// Find the matching endpoint for a given URL
    private func findMatchingEndpoint(for requestEndpoint: String) -> String? {
        // Exact match
        if mockResponses.keys.contains(requestEndpoint) {
            return requestEndpoint
        }

        // Match by prefix
        for endpoint in mockResponses.keys {
            if requestEndpoint.hasPrefix(endpoint) {
                return endpoint
            }
        }

        return nil
    }
}
#endif
