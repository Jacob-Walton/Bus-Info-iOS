import Foundation
import Combine

protocol NetworkServiceProtocol {
    /// Perform a network request
    /// - Parameters:
    ///   - endpoint: The API endpoint to call
    ///   - method: The HTTP method to use (GET, POST, etc.)
    ///   - body: The request body (optional)
    ///   - headers: Additional HTTP headers (optional)
    ///   - queryItems: URL query parameters (optional)
    ///   - authType: The type of authentication to use (optional)
    /// - Returns: A publisher that emits the decoded response or an error
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        queryItems: [URLQueryItem],
        authType: AuthType
    ) -> AnyPublisher<T, NetworkError>
}
