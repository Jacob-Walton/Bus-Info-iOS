// MARK: - HTTP & Auth Types

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum AuthType {
    case bearer // JWT token
    case apiKey // For future use (if any)
    case none   // No authentication
}

// MARK: - Network Error Handling

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatusCode(Int)
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case unexpectedError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from the server"
        case .httpStatusCode(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .unexpectedError(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}
